--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2019  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]



local debug, tmp, str, counter, r, id, pname, result, help, row, rows, cursor, errorString
local shortHelp = false
local skipHelp = false

local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+)"
local runyear, runmonth, runday, runhour, runminute, runseconds, seenTimestamp

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

function gmsg_admin()
	calledFunction = "gmsg_admin"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## Admin command functions ##################

	local function cmd_AddRemoveAdmin() --tested
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}admin add {player or steam or game ID} level {0-2}\n"
			help[1] = help[1] .. " {#}admin remove {player or steam or game ID}"
			help[2] = "Give a player admin status and a level, or take it away.\n"
			help[2] = help[2] .. "Server owners are level 0, admins are level 1 and moderators level 2.  The bot does not currently recognise other admin levels.\n"
			help[2] = help[2] .. "Or remove an admin so they become a regular player.\n"
			help[2] = help[2] .. "This does not stop them using god mode etc if they are ingame and already have dm enabled.  They must leave the server or disable dm themselves."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,admin,staff,own,mod"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.command, "admin add ") or string.find(chatvars.command, "admin remove ")) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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
			id = LookupPlayer(pname) -- done
			number = -1

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if string.find(chatvars.command, "admin add ") then
				for i=3,chatvars.wordCount,1 do
					if chatvars.words[i] == "level" then
						number = chatvars.words[i+1]
					end
				end

				if number == -1 then
					number = 1
				end

				if id ~= nil then
					-- add the steamid to the admins table
					if tonumber(number) == 0 then
						owners[id] = {}
					end

					if tonumber(number) == 1 then
						admins[id] = {}
					end

					if tonumber(number) == 2 then
						mods[id] = {}
					end

					if not isArchived then
						players[id].newPlayer = false
						players[id].silentBob = false
						players[id].walkies = false
						players[id].block = false
						players[id].exiled = false
						players[id].canTeleport = true
						players[id].botHelp = true
						players[id].accessLevel = number

						if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, silentBob = 0, walkies = 0, block = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. id) end
					else
						if botman.dbConnected then conn:execute("UPDATE playersArchived SET newPlayer = 0, silentBob = 0, walkies = 0, block = 0, exiled = 0, canTeleport = 1, botHelp = 1, accessLevel = " .. number .. " WHERE steam = " .. id) end

						conn:execute("INSERT INTO players SELECT * from playersArchived WHERE steam = " .. id)
						conn:execute("DELETE FROM playersArchived WHERE steam = " .. id)
						playersArchived[id] = nil
						loadPlayers(id)
					end

					message("say [" .. server.chatColour .. "]" .. playerName .. " has been given admin powers[-]")
					sendCommand("ban remove " .. id)
					sendCommand("admin add " .. id .. " " .. number)
				end
			else
				-- remove the steamid from the admins table
				if not isArchived then
					owners[id] = nil
					admins[id] = nil
					mods[id] = nil
					players[id].accessLevel = 90
				else
					owners[id] = nil
					admins[id] = nil
					mods[id] = nil
					playersArchived[id].accessLevel = 90
				end

				message("say [" .. server.chatColour .. "]" .. playerName .. "'s admin powers have been revoked[-]")
				sendCommand("admin remove " .. id)
			end

			setChatColour(id)

			-- save the player record to the database
			if not isArchived then
				updatePlayer(id)
			else
				updateArchivedPlayer(id)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBadItem() --tested
		local bad, action

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add/remove bad item {item} action {timeout or ban} (default action is timeout)"
			help[2] = "Add or remove an item to/from the list of bad items.  The default action is to timeout the player.\n"
			help[2] = help[2] .. "See also {#}ignore player {name} and {#}include player {name}"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,bad,item"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "bad" and chatvars.words[3] == "item" and chatvars.words[4] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. bad .. " to the list of bad items. The bot will " .. action .. " players found with it unless permitted.[-]")
				else
					irc_chat(chatvars.ircAlias, "You added " .. bad .. " to the list of bad items. The bot will " .. action .. " players found with it unless permitted")
				end
			else
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "bad item") + 9)

				badItems[bad] = nil
				if botman.dbConnected then conn:execute("DELETE FROM badItems WHERE item = '" .. escape(bad) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of bad items.[-]")
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


	local function cmd_AddRemoveBlacklistCountry() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add/remove blacklist country {US}"
			help[2] = "Add or remove a country to/from the blacklist. Note: Use 2 letter country codes only."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,black,list,cou"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and string.find(chatvars.command, "blacklist") and chatvars.words[3] == "country" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			-- country missing
			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country code required eg. US[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code required eg. US")
				end

				botman.faultyChat = false
				return true
			end

			-- country code not 2 characters long
			if string.len(chatvars.words[4]) ~= 2 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country code must be 2 characters long.[-]")
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is already blacklisted.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been blacklisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been blacklisted.")
				end
			else
				-- country already in blacklist
				if not blacklistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is not blacklisted. Nothing to do.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been removed from the blacklist.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been removed from the blacklist.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveDonor() --tested
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add donor {player name} level {0 to 7} expires {number} week or month or year\n"
			help[1] = help[1] .. " {#}remove donor {player name}"
			help[2] = "Give a player donor status.  This doesn't have to involve money.  Donors get a few perks above other players but no items or " .. server.moneyPlural .. ".\n"
			help[2] = help[2] .. "Level and expiry are optional.  The default is level 1 and expiry 10 years.\n"
			help[2] = help[2] .. "You can also temporarily raise everyone to donor level with {#}override access."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,donor"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "donor" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			tmp = {}

			-- parameter collection and validation
			if string.find(chatvars.command, "level") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " donor ") + 7, string.find(chatvars.command, " level ") - 1)
			else
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " donor ") + 7)
			end

			if string.find(chatvars.command, "expires") and not string.find(chatvars.command, "level") then
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, " donor ") + 7, string.find(chatvars.command, " expires ") - 1)
			end

			tmp.pname = string.trim(tmp.pname)

			-- no player name given
			if tmp.pname == "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player name required after donor.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player name required after donor.")
				end

				botman.faultyChat = false
				return true
			end

			tmp.id = LookupPlayer(tmp.pname) -- done

			if tmp.id == 0 then
				tmp.id = LookupArchivedPlayer(tmp.pname)

				if not (tmp.id == 0) then
					playerName = playersArchived[tmp.id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.id].name
				isArchived = false
			end

			if string.find(chatvars.command, "level") then
				tmp.level = math.abs(chatvars.numbers[1])

				-- level missing or out of range
				if tmp.level == nil or tmp.level > 7 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Level must be a number from 0 to 7.[-]")
					else
						irc_chat(chatvars.ircAlias, "Level must be a number from 0 to 7.")
					end

					botman.faultyChat = false
					return true
				end
			else
				tmp.level = 10
			end

			if string.find(chatvars.command, "expires") then
				tmp.expiry = string.sub(chatvars.command, string.find(chatvars.command, "expires") + 8)
				tmp.expiry = calcTimestamp(tmp.expiry)

				-- expiry in the past
				if tonumber(tmp.expiry) <= os.time() then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Invalid expiry entered. Expected {number} {week or month or year} eg. 1 month.[-]")
					else
						irc_chat(chatvars.ircAlias, "Invalid expiry entered. Expected {number} {week or month or year} eg. 1 month.")
					end

					botman.faultyChat = false
					return true
				end
			else
				tmp.expiry = calcTimestamp("10 years")
			end

			-- add or update a donor
			if chatvars.words[1] == "add" then
				if (chatvars.words[3] == nil) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add donors with optional level and expiry. Defaults level 1 and 10 years.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add donor bob level 5 expires 1 week (or month or year)[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expires automatically. 2nd protected base becomes unprotected 1 week later.[-]")
					else
						irc_chat(chatvars.ircAlias, "Add donors with optional level and expiry. Defaults level 10 and 10 years.")
						irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "add donor bob level 5 expires 1 week (or month or year)")
						irc_chat(chatvars.ircAlias, "Expires automatically. 2nd protected base becomes unprotected 1 week later.")
					end

					botman.faultyChat = false
					return true
				end

				if not isArchived then
					tmp.sql = "UPDATE players SET donor = 1"
					tmp.sql = tmp.sql .. ", donorExpiry = " .. tmp.expiry .. ", donorLevel = " .. tmp.level .. ", maxWaypoints = " .. server.maxWaypointsDonors

					-- set the donor flag to true
					players[tmp.id].donor = true
					players[tmp.id].donorLevel = tmp.level
					players[tmp.id].donorExpiry = tmp.expiry
					players[tmp.id].maxWaypoints = server.maxWaypointsDonors
				else
					tmp.sql = "UPDATE playersArchived SET donor = 1"
					tmp.sql = tmp.sql .. ", donorExpiry = " .. tmp.expiry .. ", donorLevel = " .. tmp.level .. ", maxWaypoints = " .. server.maxWaypointsDonors

					-- set the donor flag to true
					playersArchived[tmp.id].donor = true
					playersArchived[tmp.id].donorLevel = tmp.level
					playersArchived[tmp.id].donorExpiry = tmp.expiry
					playersArchived[tmp.id].maxWaypoints = server.maxWaypointsDonors
				end

				if botman.dbConnected then conn:execute(tmp.sql .. " WHERE steam = " .. tmp.id) end

				-- also add them to the bot's whitelist
				whitelist[tmp.id] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES (" .. tmp.id .. ")") end

				-- remove any ban against them
				sendCommand("ban remove " .. tmp.id)

				-- create or update the donor record on the shared database
				if server.serverGroup ~= "" then
					connBots:execute("INSERT INTO donors (donor, donorLevel, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. tmp.level .. ", " .. tmp.expiry .. ", " .. tmp.id .. "," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")
					connBots:execute("UPDATE donors SET donor = 1, donorLevel = " .. tmp.level .. ", donorExpiry = " .. tmp.expiry .. " WHERE steam = " .. tmp.id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
				end

				message("pm " .. tmp.id .. " [" .. server.chatColour .. "]You have been given donor privileges until " .. os.date("%d-%b-%Y",  tmp.expiry) .. ". Thank you for being awesome! =D[-]")
				irc_chat(server.ircMain, playerName .. " donor status expires on " .. os.date("%d-%b-%Y",  tmp.expiry))

				if chatvars.ircid ~= 0 then
					irc_chat(chatvars.ircAlias, playerName .. " donor status expires on " .. os.date("%d-%b-%Y",  tmp.expiry))
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " is now a donor until " .. os.date("%d-%b-%Y",  tmp.expiry) .. ".[-]")
				end
			else
				-- remove a donor

				if not isArchived then
					-- set the donor flag to false
					players[tmp.id].donor = false
					players[tmp.id].donorLevel = 0
					players[tmp.id].donorExpiry = os.time() - 1
					players[tmp.id].maxWaypoints = server.maxWaypoints

					if botman.dbConnected then conn:execute("UPDATE players SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. tmp.id) end
				else
					-- set the donor flag to false
					playersArchived[tmp.id].donor = false
					playersArchived[tmp.id].donorLevel = 0
					playersArchived[tmp.id].donorExpiry = os.time() - 1
					playersArchived[tmp.id].maxWaypoints = server.maxWaypoints

					if botman.dbConnected then conn:execute("UPDATE playersArchived SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. tmp.id) end
				end

				-- to prevent the player having too many waypoints, we delete them.
				if botman.dbConnected then conn:execute("DELETE FROM waypoints WHERE steam = " .. tmp.id) end

				-- reload the player's waypoints
				loadWaypoints(tmp.id)

				if server.serverGroup ~= "" then
					connBots:execute("UPDATE donors SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. tmp.id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " no longer has donor status.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " no longer has donor status.")
				end
			end

			setChatColour(tmp.id)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveRestrictedItem() --tested
		local bad, item, qty, access, action

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add restricted item {item name} qty {count} action {action} access {level}\n"
			help[1] = help[1] .. " {#}remove restricted item {item name}"
			help[2] = "Add an item to the list of restricted items.\n"
			help[2] = help[2] .. "Valid actions are timeout, ban, exile and watch\n"
			help[2] = help[2] .. "eg. {#}add restricted item tnt qty 5 action timeout access 90\n"
			help[2] = help[2] .. "Players with access > 90 will be sent to timeout for more than 5 tnt."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,rest,item"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or (string.find(chatvars.command, "remove")) or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and chatvars.words[2] == "restricted" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "add" and chatvars.words[3] == nil) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Add an item to the inventory scanner for special attention.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players with access > 90 will be sent to timeout for more than 5 tnt.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch[-]")
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Invalid action entered, using timeout instead.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile, and watch.[-]")
					else
						irc_chat(chatvars.ircAlias, "Invalid action entered, using timeout instead.")
						irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile, and watch.")
					end
				end

				if item == "" or access == 100 then
					if (chatvars.playername ~= "Server") then
						if item == "" and access < 100 then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item name required.[-]")
						end

						if item ~= "" and access == 100 then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Access level required.[-]")
						end

						if item == "" and access == 100 then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item name and access level required.[-]")
						end

						if item == "" then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout[-]")
						else
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item " .. item .. " qty 20 access 99 action timeout[-]")
						end

						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile. Bans last 1 day.[-]")
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
						conn:execute("DELETE FROM memRestrictedItems WHERE item = '" .. escape(bad) .. "'")

						conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
						conn:execute("INSERT INTO memRestrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.[-]")
					else
						irc_chat(chatvars.ircAlias, "You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.")
					end
				end
			else
				-- remove restricted item
				bad = string.sub(chatvars.commandOld, string.find(chatvars.command, "restricted item") + 16)

				if botman.dbConnected then
					conn:execute("DELETE FROM restrictedItems WHERE item = '" .. escape(bad) .. "'")
					conn:execute("DELETE FROM memRestrictedItems WHERE item = '" .. escape(bad) .. "'")
				end

				--restrictedItems[bad] = nil
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of restricted items[-]")
			end

			loadRestrictedItems()

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveWhitelistCountry() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add whitelist country {US}\n"
			help[1] = help[1] .. " {#}remove whitelist country {US}"
			help[2] = "Add or remove a country to/from the whitelist. Note: Use 2 letter country codes."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,white,list,cou"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" or chatvars.words[1] == "remove") and string.find(chatvars.command, "whitelist") and chatvars.words[3] == "country" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			-- country missing
			if chatvars.words[4] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country code required eg. US[-]")
				else
					irc_chat(chatvars.ircAlias, "Country code required eg. US")
				end

				botman.faultyChat = false
				return true
			end

			-- country code not 2 characters long
			if string.len(chatvars.words[4]) ~= 2 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country code must be 2 characters long.[-]")
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is already whitelisted.[-]")
					else
						irc_chat(chatvars.ircAlias, chatvars.words[4] .. " is already whitelisted.")
					end

					if server.whitelistCountries ~= "" then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been whitelisted.")
				end
			else
				-- country already in whitelist
				if not whitelistedCountries[chatvars.words[4]] then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. chatvars.words[4] .. " is not whitelisted. Nothing to do.[-]")
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Country " .. chatvars.words[4] .. " has been removed from the whitelist.[-]")
				else
					irc_chat(chatvars.ircAlias, "Country " .. chatvars.words[4] .. " has been removed from the whitelist.")
				end
			end

			if server.whitelistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "No countries are whitelisted.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ArrestPlayer() --tested
		local reason, prisoner, prisonerid

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}arrest {player name}\n"
			help[1] = help[1] .. " {#}arrest {player name} reason {why arrested}"
			help[2] = "Send a player to prison.  If the location prison does not exist they are temp-banned instead."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "arre,jail,prison,player,reason"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "arrest") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "jail"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "arrest") then
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

			reason = "Arrested by admin"

			if string.find(chatvars.command, " reason ") then
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7, string.find(chatvars.command, " reason "))
				reason = string.sub(chatvars.commandOld, string.find(chatvars.command, " reason ") + 8)
			else
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "arrest ") + 7)
			end

			reason = string.trim(reason)
			prisoner = string.trim(prisoner)
			prisonerid = LookupPlayer(prisoner) -- done

			if prisonerid == 0 then
				prisonerid = LookupArchivedPlayer(prisoner)

				if not (prisonerid == 0) then
					prisoner = playersArchived[prisonerid].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			else
				prisoner = players[prisonerid].name
				isArchived = false
			end

			prisoner = players[prisonerid].name

			if (players[prisonerid]) then
				if (players[prisonerid].timeout or players[prisonerid].botTimeout) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
					else
						irc_chat(chatvars.ircAlias, prisoner .. " is in timeout. Return them first")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.playername ~= "Server") then
				if (accessLevel(prisonerid) < 3 and botman.ignoreAdmins == true and prisonerid ~= chatvars.playerid) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff can not be arrested.[-]")
					else
						irc_chat(chatvars.ircAlias, "Staff can not be arrested.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if locations["prison"] == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Create a location called prison first. Sending them to timeout instead..[-]")
				else
					irc_chat(chatvars.ircAlias, "Create a location called prison first. Sending them to timeout instead.")
				end

				gmsg(server.commandPrefix .. "timeout " .. prisoner)
				botman.faultyChat = false
				return true
			end

			arrest(prisonerid, reason, 10000, 44640) -- bail 10,000  prison time 1 month

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BanUnbanPlayer() --tested
		local steam, owner, pname, reason, duration, rows, cursor, errorString, playerName, unknownPlayer

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}ban {player name} (ban for 10 years with the reason 'banned')\n"
			help[1] = help[1] .. " {#}ban {player name} reason {reason for ban} (ban for 10 years with the reason you provided)\n"
			help[1] = help[1] .. " {#}ban {player name} time {number} hour or day or month or year reason {reason for ban}\n"
			help[1] = help[1] .. " {#}unban {player name} (This will also remove global bans issued by this bot against this player.  It will not remove global bans issued elsewhere.\n"
			help[1] = help[1] .. " {#}gblban {player name} reason {reason for ban}"
			help[2] = "Ban a player from the server.  You can optionally give a reason and a duration. The default is a 10 year ban with the reason 'banned'.\n"
			help[2] = help[2] .. "Global bans are vetted before they become active.  If the player is later caught hacking by a bot and they have pending global bans, a new active global ban is added automatically."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "ban,gbl,global,player,reason"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black") or string.find(chatvars.command, "gbl") or string.find(chatvars.command, "glob"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "ban" or chatvars.words[1] == "unban" or chatvars.words[1] == "gblban") and chatvars.words[2] ~= nil then
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

			-- gather info for the ban
			reason = "banned"
			duration = "10 years"
			unknownPlayer = false
			playerName = "Not Sure (unknown player)"

			-- someone did ban remove instead of unban so we'll fix their command for them.
			if string.find(chatvars.command, "ban remove") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)
				chatvars.words[1] = "unban"
				chatvars.command = "unban " .. pname
			end

			if string.find(chatvars.command, "reason") then
				reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "reason ") + 7)
			end

			if not string.find(chatvars.command, " reason ") and not string.find(chatvars.command, " time ") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4)
			end

			if string.find(chatvars.command, "reason") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " reason ") - 1)

				if chatvars.words[1] ~= "gblban" then
					if string.find(chatvars.command, " time ") then
						pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " time ") - 1)
					end
				else
					if string.find(chatvars.command, "gblban add") then
						pname = string.sub(chatvars.command, string.find(chatvars.command, "ban add ") + 8, string.find(chatvars.command, " reason ") - 1)
					else
						pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " reason ") - 1)
					end
				end
			end

			if string.find(chatvars.command, "time") then
				if string.find(chatvars.command, "reason") then
					duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5, string.find(chatvars.command, " reason ") - 1)
				else
					duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5)
				end

				pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, " time ") - 1)
			end

			if chatvars.words[1] == "unban" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "unban ") + 6)
			end

			pname = string.trim(pname)
			steam, owner = LookupPlayer(pname)

			if steam == 0 then
				steam, owner = LookupArchivedPlayer(pname)
				if not (steam == 0) then
					playerName = playersArchived[steam].name
				else
					unknownPlayer = true

					if isValidSteamID(pname) then
						steam = pname
						owner = pname
					end
				end
			else
				playerName = players[steam].name
			end

			if chatvars.words[1] == "unban" then
				sendCommand("ban remove " .. steam)

				if steam ~= owner then
					-- also unban the owner id
					sendCommand("ban remove " .. owner)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " has been unbanned.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " has been unbanned.")
				end

				-- also delete the ban record in the shared bots database.  If the player was global banned from here, this will remove that ban as well.
				connBots:execute("DELETE FROM bans where steam = " .. steam .. " OR steam = " .. owner .. " AND botID = " .. server.botID)

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "ban" then
				-- don't ban if player is an admin :O
				if accessLevel(steam) < 3 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You what?  You want to ban one of your own admins?   [DENIED][-]")
					else
						irc_chat(chatvars.ircAlias, "You what?  You want to ban one of your own admins?   [DENIED]")
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] ~= "gblban" then
				-- issue a local ban
				banPlayer(steam, duration, reason, chatvars.playerid)
			else
				-- issue a global ban
				if steam ~= 0 then
					-- don't ban if player is an admin :O
					if accessLevel(steam) < 3 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You what?  You want to global ban one of your own admins?   [DENIED][-]")
						else
							irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of your own admins?   [DENIED]")
						end

						botman.faultyChat = false
						return true
					end
				end

				cursor,errorString = connBots:execute("SELECT * FROM bans where steam = " .. steam .. " or steam = " .. owner .. " AND botID = " .. server.botID)
				rows = cursor:numrows()

				if rows == 0 then
					connBots:execute("INSERT INTO bans (steam, reason, GBLBan, GBLBanReason, botID) VALUES (" .. steam .. ",'" .. escape(reason) .. "',1,'" .. escape(reason) .. "'," .. server.botID .. ")")
					-- issue a local ban as well
					banPlayer(steam, duration, reason, chatvars.playerid)
				else
					connBots:execute("UPDATE bans set GBLBan = 1, GBLBanReason = '" .. escape(reason) .. "' WHERE steam = " .. steam .. " or steam = " .. owner .. " AND botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " with steam id " .. steam .. " has been submitted to the global ban list for approval.[-]")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Until approved, it will only raise an alert when the player joins another server.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " with steam id " .. steam .. " has been submitted to the global ban list for approval.")
					irc_chat(chatvars.ircAlias, "Until approved, it will only raise an alert when the player joins another server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BlockChatCommandsForPlayer() --tested
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}block/unblock {name}"
			help[2] = "Block/Unblock a player from using any bot commands or command the bot from IRC."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "block,player,comm,irc,bot"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "block") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if (chatvars.words[1] == "block") then
				if accessLevel(id) < 3 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Action not permitted against admins.[-]")
					else
						irc_chat(chatvars.ircAlias, "Action not permitted against admins.")
					end

					botman.faultyChat = false
					return true
				end

				if not isArchived then
					players[id].block = true
				else
					playersArchived[id].block = true
				end

				if botman.dbConnected then conn:execute("UPDATE playersArchived SET block=1 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. playerName .. " is blocked from talking to the bot.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " is blocked from talking to the bot.")
				end
			else
				if not isArchived then
					players[id].block = false
				else
					playersArchived[id].block = false
				end

				if botman.dbConnected then conn:execute("UPDATE players SET block=0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. playerName .. " can talk to the bot.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " can talk to the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BurnPlayer() --tested (ouch)
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}burn {player name}"
			help[2] = "Set a player on fire.  It usually kills them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "burn,player,buff"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "burn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "burn") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			id = chatvars.playerid -- you look hot

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and can't feel the burn.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and can't feel the burn.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-buffplayer " .. id .. " burning") -- yeah baby!
			else
				sendCommand("buffplayer " .. id .. " buffBurningMolotov") -- yeah baby!
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You set " .. players[id].name .. " on fire![-]")

				if accessLevel(id) < 3 then
					if chatvars.playerid == id then
						message("pm " .. id .. " [" .. server.alertColour .. "]You set yourself on fire!  Should'a listened to the Surgeon General.[-]")
					else
						message("pm " .. id .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " set you on fire![-]")
					end
				end
			else
				irc_chat(chatvars.ircAlias, "You set " .. players[id].name .. " on fire!")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ArchivePlayers() --tested
		local k,v

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}archive players"
			help[2] = "Archive players that haven't played in 60 days, aren't staff, banned, or a donor.\n"
			help[2] = help[2] .. "This should speed the bot up on servers that have seen thousands of players over time as the bot won't need to search so many player records.\n"
			help[2] = help[2] .. "Archived players are still accessible and searchable but are removed from the main players table.  If a player comes back they are automatically restored from the archive."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "arch,play"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "arch") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "archive" and chatvars.words[2] == "players" then
			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]This command has been disabled by Smeg until further notice. There's a bug in it.", chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			else
				irc_chat(chatvars.ircAlias, "This command has been disabled by Smeg until further notice. There's a bug in it.")
				botman.faultyChat = false
				return true
			end



			-- if (chatvars.playername ~= "Server") then
				-- if (chatvars.accessLevel > 1) then
					-- message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					-- botman.faultyChat = false
					-- return true
				-- end
			-- else
				-- if (chatvars.accessLevel > 1) then
					-- irc_chat(chatvars.ircAlias, "This command is restricted.")
					-- botman.faultyChat = false
					-- return true
				-- end
			-- end

			-- if (chatvars.playername ~= "Server") then
				-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players (except staff) who have not played in 60 days will be archived.  The bot may become un-responsive during this time.[-]")
			-- else
				-- irc_chat(chatvars.ircAlias, "Players (except staff) who have not played in 60 days will be archived.  The bot may become un-responsive during this time.")
			-- end

			-- botman.archivePlayers = true

			-- --	first flag everyone except staff as notInLKP.  We will remove that flag as we find them in LKP.
			-- for k,v in pairs(players) do
				-- if tonumber(v.accessLevel) > 3 then
					-- v.notInLKP = true
				-- else
					-- v.notInLKP = false
				-- end
			-- end

			-- tempTimer( 10, [[sendCommand("lkp")]] )
			-- botman.faultyChat = false
			-- return true
		end
	end


	local function cmd_ClearBlacklist() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear country blacklist"
			help[2] = "Remove all countries from the blacklist. (yay?)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "clear,black,list,cou"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "clear" and chatvars.words[2] == "country" and chatvars.words[3] == "blacklist") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			blacklistedCountries = {}
			server.blacklistCountries = ""

			conn:execute("UPDATE server SET blacklistCountries = ''")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The country blacklist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The country blacklist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearWhitelist() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}clear country whitelist"
			help[2] = "Remove all countries from the whitelist."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "clear,white,list,cou"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "clear" and chatvars.words[2] == "country" and chatvars.words[3] == "whitelist") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			whitelistedCountries = {}
			server.whitelistCountries = ""

			conn:execute("UPDATE server SET whitelistCountries = ''")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The country whitelist has been cleared.[-]")
			else
				irc_chat(chatvars.ircAlias, "The country whitelist has been cleared.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CoolPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}cool {player name}"
			help[2] = "Cool a player or yourself if no name given."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "cool,player,buff"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "cool") then
			if locations["cool"] then
				botman.faultyChat = false
				return false
			end

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

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now.  They aren't cool enough.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now. They aren't cool enough.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("buffplayer " .. id .. " redTeaCooling")  -- stay frosty
			else
				sendCommand("bc-buffplayer " .. id .. " buffYuccaJuiceCooling")  -- stay frosty
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is cooling down.[-]")
			else
				irc_chat(chatvars.ircAlias, players[id].name .. " is cooling down.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CurePlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}cure {player name}"
			help[2] = "Cure a player or yourself if no name given."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "cure,player,buff"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cure") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "cure") then
			if locations["cure"] then
				botman.faultyChat = false
				return false
			end

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

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now. Next patient please![-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now. Next patient please!")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-buffplayer " .. id .. " cured")
				sendCommand("bc-debuffplayer " .. id .. " dysentery")  -- It's Debuffy The Zombie Slayer! :D
				sendCommand("bc-debuffplayer " .. id .. " dysentery2")
				sendCommand("bc-debuffplayer " .. id .. " foodPoisoning")
				sendCommand("bc-debuffplayer " .. id .. " infection")
				sendCommand("bc-debuffplayer " .. id .. " infection1")
				sendCommand("bc-debuffplayer " .. id .. " infection2")
				sendCommand("bc-debuffplayer " .. id .. " infection3")
				sendCommand("bc-debuffplayer " .. id .. " infection4")
			else
				sendCommand("bc-debuffplayer " .. id .. " buffIllDysentery1")  -- It's Debuffy The Zombie Slayer! :D
				sendCommand("bc-debuffplayer " .. id .. " buffIllDysentery2")
				sendCommand("bc-debuffplayer " .. id .. " buffIllFoodPoisoning1")
				sendCommand("bc-debuffplayer " .. id .. " buffIllFoodPoisoning2")
				sendCommand("bc-debuffplayer " .. id .. " buffIllPneumonia1")
				sendCommand("bc-debuffplayer " .. id .. " buffIllInfection1")
				sendCommand("bc-debuffplayer " .. id .. " buffIllInfection1")
				sendCommand("bc-debuffplayer " .. id .. " buffIllInfection1")

			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You cured " .. players[id].name .. "[-]")
			else
				irc_chat(chatvars.ircAlias, "You cured " .. players[id].name)
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
				if tonumber(server.gameVersionNumber) < 17 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " " .. item .. " /c=" .. quantity .. " /q=600 /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " " .. item .. " " .. quantity .. " 600"
					end
				else
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " " .. item .. " /c=" .. quantity .. " /q=6 /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " " .. item .. " " .. quantity .. " 6"
					end
				end
			else
				if tmp.quantity < quantity then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " " .. item .. " /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " " .. item .. " " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, item)

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if not ignoreQuality then
					if tmp.quality < 100 then
						if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
						tmp.gaveStuff = true
					end
				end
			end
		end

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}equip admin"
			help[2] = "Spawn various items on you.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "equip,admin,item"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "equip") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "equip" and chatvars.words[2] == "admin") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.gaveStuff = false
			tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
			tmp.equipment = igplayers[chatvars.playerid].equipment

			if tonumber(server.gameVersionNumber) >= 17 then
				giveItem("jetPackAdmin")
				giveItem("meleeToolHammerOfGodAdmin")
				giveItem("meleeToolPaintToolAdmin")
				giveItem("meleeToolWrenchAdmin")
				giveItem("pimpCoatAdmin")
				giveItem("rocketBootsAdmin")
				giveItem("gunPistolAdmin")
				giveItem("gunToolDiggerAdmin")
			else
				giveItem("auger")
				giveItem("chainsaw")
				giveItem("nailgun")
				giveItem("miningHelmet")
				giveItem("militaryVest")
				giveItem("militaryLegArmor")
				giveItem("militaryBoots")
				giveItem("militaryGloves")
				giveItem("leatherDuster")
				giveItem("gunMP5")
				giveItem("redTea", true, 10)
				giveItem("gasCan", true, 400)
				giveItem("meatStew", true, 20)
				giveItem("firstAidKit", true, 10)
				giveItem("antibiotics", true, 10)
				giveItem("9mmBullet", true, 500)
			end

			if tmp.gaveStuff then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]We deliver :)[-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have enough stuff and its not shitty enough to replace yet :P[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ExilePlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}exile {player name}"
			help[2] = "Bannish a player to a special location called {#}exile which must exist first.  While exiled, the player will not be able to command the bot."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "exile,player"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "exile")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "exile" and chatvars.words[2] ~= nil) then
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

			pname = chatvars.words[2]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if id ~= 0 then
				-- flag the player as exiled
				if not isArchived then
					players[id].exiled = true
					players[id].silentBob = true
					players[id].canTeleport = false
				else
					playersArchived[id].exiled = true
					playersArchived[id].silentBob = true
					playersArchived[id].canTeleport = false
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " has been exiled.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " has been exiled.")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FreePlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}free {player name}"
			help[2] = "Release the player from exile, however it does not return them.  They can type {#}return or you can return them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "exile,player,free,rele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exile") or string.find(chatvars.command, "free"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "free") then
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

			pname = chatvars.words[2]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if id ~= 0 then
				-- flag the player as no longer exiled
				if not isArchived then
					players[id].exiled = false
					players[id].silentBob = false
					players[id].canTeleport = true
				else
					playersArchived[id].exiled = false
					playersArchived[id].silentBob = false
					playersArchived[id].canTeleport = true
				end

				message("say [" .. server.chatColour .. "]" .. playerName .. " has been released from exile! :D[-]")
				if botman.dbConnected then conn:execute("UPDATE players SET exiled = 0, silentBob = 0, canTeleport = 1 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveAdminSupplies() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}supplies"
			help[2] = "Spawn various items on you like equip admin does but no armour or guns.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "supp,item,give,admin"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give") or string.find(chatvars.command, "item"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "supplies") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.gaveStuff = false
			tmp.inventory = igplayers[chatvars.playerid].pack .. igplayers[chatvars.playerid].belt
			tmp.equipment = igplayers[chatvars.playerid].equipment

			if not string.find(tmp.inventory, "edTea") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=10 /silent" -- A16
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " drinkJarRedTea /c=10 /silent" -- A17
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " redTea 10"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " drinkJarRedTea 10"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "redTea")
				else
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "drinkJarRedTea")
				end

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " drinkJarRedTea /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " redTea " .. 10 - tonumber(tmp.quantity)
						else
							tmp.cmd = "give " .. chatvars.playerid .. " drinkJarRedTea " .. 10 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(string.lower(tmp.inventory), "ascan") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=400 /silent"
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " ammoGasCan /c=400 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " gasCan 400"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " ammoGasCan 400"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gasCan")
				else
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "ammoGasCan")
				end

				if tonumber(tmp.quantity) < 400 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=" .. 400 - tonumber(tmp.quantity) .. " /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " ammoGasCan /c=" .. 400 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " gasCan " .. 400 - tonumber(tmp.quantity)
						else
							tmp.cmd = "give " .. chatvars.playerid .. " ammoGasCan " .. 400 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "eatStew") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=20 /silent"
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " foodMeatStew /c=20 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " meatStew 20"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " foodMeatStew 20"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "meatStew")
				else
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "foodMeatStew")
				end

				if tonumber(tmp.quantity) < 20 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=" .. 20 - tonumber(tmp.quantity) .. " /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " foodMeatStew /c=" .. 20 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " meatStew " .. 20 - tonumber(tmp.quantity)
						else
							tmp.cmd = "give " .. chatvars.playerid .. " foodMeatStew " .. 20 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "irstAidKit") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=10 /silent"
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " medicalFirstAidKit /c=10 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit 10"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " medicalFirstAidKit 10"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "firstAidKit")
				else
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "medicalFirstAidKit")
				end

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " medicalFirstAidKit /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit " .. 10 - tonumber(tmp.quantity)
						else
							tmp.cmd = "give " .. chatvars.playerid .. " medicalFirstAidKit " .. 10 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "ntibiotics") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=10 /silent"
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " drugAntibiotics /c=10 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " antibiotics 10"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " drugAntibiotics 10"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "antibiotics")
				else
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "drugAntibiotics")
				end

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " drugAntibiotics /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " antibiotics " .. 10 - tonumber(tmp.quantity)
						else
							tmp.cmd = "give " .. chatvars.playerid .. " drugAntibiotics " .. 10 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "shotgunShell") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=500 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell 500"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "shotgunShell")

				if tonumber(tmp.quantity) < 500 then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=" .. 500 - tonumber(tmp.quantity) .. " /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell " .. 500 - tonumber(tmp.quantity)
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory .. tmp.equipment, "iningHelmet") then
				if server.stompy then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " miningHelmet /c=1 /q=600 /silent"
					else
						tmp.cmd = "bc-give " .. chatvars.playerid .. " armorMiningHelmet /c=1 /q=6 /silent"
					end
				else
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.cmd = "give " .. chatvars.playerid .. " miningHelmet 1 600"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " armorMiningHelmet 1 6"
					end
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tonumber(server.gameVersionNumber) < 17 then
					tmp.found, tmp.quality = getEquipment(tmp.equipment, "miningHelmet")
				else
					tmp.found, tmp.quality = getEquipment(tmp.equipment, "armorMiningHelmet")
				end

				if not tmp.found then
					if tonumber(server.gameVersionNumber) < 17 then
						tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "miningHelmet")
					else
						tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "armorMiningHelmet")
					end
				end

				if not tmp.found then
					if server.stompy then
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "bc-give " .. chatvars.playerid .. " miningHelmet /c=1 /q=600 /silent"
						else
							tmp.cmd = "bc-give " .. chatvars.playerid .. " armorMiningHelmet /c=1 /q=6 /silent"
						end
					else
						if tonumber(server.gameVersionNumber) < 17 then
							tmp.cmd = "give " .. chatvars.playerid .. " miningHelmet 1 600"
						else
							tmp.cmd = "give " .. chatvars.playerid .. " armorMiningHelmet 1 6"
						end
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end

			if tmp.gaveStuff then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]SUPPLIES![-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You don't need any more supplies :P[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveBackClaims()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}give claim/key/lcb"
			help[2] = "The bot can despawn player placed claims in reset zones.  This command is for them to request them back from the bot.\n"
			help[2] = help[2] .. "It will only return the number that it took away.  If it isn't holding any, it won't give any back."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "give,claim,lcb,keys"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give") or string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "give" and (string.find(chatvars.words[2], "claim") or string.find(chatvars.words[2], "key") or string.find(chatvars.words[2], "lcb")) then
			CheckClaimsRemoved(chatvars.playerid)

			if players[chatvars.playerid].removedClaims > 0 then
				if server.stompy then
					sendCommand("bc-give " .. chatvars.playerid .. " keystoneBlock /c=" .. players[chatvars.playerid].removedClaims .. " /silent")
				else
					sendCommand("give " .. chatvars.playerid .. " keystoneBlock " .. players[chatvars.playerid].removedClaims)
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I was holding " .. players[chatvars.playerid].removedClaims .. " keystones for you. Check the ground for them if they didn't go directly into your inventory.[-]")
				players[chatvars.playerid].removedClaims = 0
				if botman.dbConnected then conn:execute("UPDATE players SET removedClaims = 0 WHERE steam = " .. chatvars.playerid) end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have no keystones to give you at this time.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveEveryoneItem()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}give everyone {item} {amount} {quality}"
			help[2] = "Give everyone that is playing on the server right now an amount of an item. The default is to give 1 item.\n"
			help[2] = help[2] .. "If quality is not given, it will have a random quality for each player.\n"
			help[2] = help[2] .. "Anyone not currently playing will not receive the item."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "give,item,all,ever"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "give" and chatvars.words[2] == "everyone") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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
				if tmp.quality then
					if server.stompy then
						sendCommand("bc-give " .. k .. " " .. chatvars.wordsOld[3] .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality .. " /silent")
					else
						sendCommand("give " .. v.id .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity .. " " .. tmp.quality)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", k, server.chatColour, chatvars.wordsOld[3]))
					end
				else
					if server.stompy then
						sendCommand("bc-give " .. k .. " " .. chatvars.wordsOld[3] .. " /c=" .. tmp.quantity .. " /silent")
					else
						sendCommand("give " .. v.id .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", k, server.chatColour, chatvars.wordsOld[3]))
					end
				end
			end

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]You gave everyone playing right now %s %s[-]", chatvars.playerid, server.chatColour, tmp.quantity, chatvars.wordsOld[3]))
			else
				irc_chat(chatvars.ircAlias, string.format("You gave everyone playing right now %s %s", tmp.quantity, chatvars.wordsOld[3]))
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GivePlayerItem()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}give player {joe} item {item} {amount} {quality}\n"
			help[1] = help[1] .. " {#}give player {joe} item {item} {amount} {quality} message {say something here}"
			help[2] = "Give a specific player amount of an item. The default is to give 1 item.\n"
			help[2] = help[2] .. "The player does not need to be on the server.  They will receive the item and optional message when they next join.\n"
			help[2] = help[2] .. "You can give more items but only 1 item type per command.  Items are given in the same order so you could include a message with the first item and they will read that first."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "give,item,play"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "give" and chatvars.words[2] == "player" and string.find(chatvars.command, "item") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			tmp.quantity = 1

			if chatvars.numbers then
				if chatvars.numbers[1] then
					tmp.quantity = chatvars.numbers[1]
				end

				if chatvars.numbers[2] then
					tmp.quality = chatvars.numbers[2]
				end
			end

			for i=3,chatvars.wordCount,1 do
				if chatvars.words[i] == "item" then
					tmp.item = chatvars.wordsOld[i+1]
				end
			end

			if string.find(chatvars.command, "message") then
				tmp.message = string.sub(chatvars.commandOld, string.find(chatvars.command, "message ") + 8)
			end

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " item ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)

			if tmp.id == 0 then
				tmp.id = LookupArchivedPlayer(tmp.pname)

				if not (tmp.id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if igplayers[tmp.id] then
				if tmp.quality then
					if server.stompy then
					dbug("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality)
						sendCommand("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality)
					else
						sendCommand("give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", tmp.id, server.chatColour, tmp.item))
					end
				else
					if server.stompy then
					dbug("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity)
						sendCommand("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity)
					else
						sendCommand("give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", tmp.id, server.chatColour, tmp.item))
					end
				end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]You gave %s %s %s[-]",chatvars.playerid, server.chatColour, players[tmp.id].name, tmp.quantity, tmp.item))
				else
					irc_chat(chatvars.ircAlias, string.format("You gave %s %s %s", players[tmp.id].name, tmp.quantity, tmp.item))
				end
			else
				-- queue the give and optional message for later when the player joins the server
				if tmp.quality then
					if server.stompy then
						tmp.cmd = "bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality
					else
						tmp.cmd = "give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality
					end
				else
					if server.stompy then
						tmp.cmd = "bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity
					else
						tmp.cmd = "give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity
					end
				end

				if botman.dbConnected then conn:execute("INSERT into connectQueue (steam, command) VALUES (" .. tmp.id .. ", '" .. escape(tmp.cmd) .. "')") end

				if tmp.message then
					tmp.cmd = "pm " .. tmp.id .. " [" .. server.chatColour .. "]" .. tmp.message .. "[-]"
					if botman.dbConnected then conn:execute("INSERT into connectQueue (steam, command) VALUES (" .. tmp.id .. ", '" .. escape(tmp.cmd) .. "')") end

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]When %s next joins the server they will get %s %s with the message %s[-]",chatvars.playerid, server.chatColour, players[tmp.id].name, tmp.quantity, tmp.item, tmp.message))
					else
						irc_chat(chatvars.ircAlias, string.format("When %s next joins the server they will get %s %s with the message %s", players[tmp.id].name, tmp.quantity, tmp.item, tmp.message))
					end
				else
					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]When %s next joins the server they will get %s %s[-]",chatvars.playerid, server.chatColour, players[tmp.id].name, tmp.quantity, tmp.item))
					else
						irc_chat(chatvars.ircAlias, string.format("When %s next joins the server they will get %s %s", players[tmp.id].name, tmp.quantity, tmp.item))
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GotoPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}goto {player or steam or game ID}"
			help[2] = "Teleport to the current position of a player.  This works with offline players too."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "give,item,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "goto" and chatvars.words[2] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout or players[chatvars.playerid].botTimeout) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot " .. server.commandPrefix .. "goto anywhere until you are released.[-]")
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "goto ") + 5)

			-- first record the current x y z
			players[chatvars.playerid].xPosOld = chatvars.intX
			players[chatvars.playerid].yPosOld = chatvars.intY
			players[chatvars.playerid].zPosOld = chatvars.intZ

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			end

			-- then teleport to the player
			if not isArchived then
				cmd = "tele " .. chatvars.playerid .. " " .. players[id].xPos + 1 .. " " .. players[id].yPos .. " " .. players[id].zPos
			else
				cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[id].xPos + 1 .. " " .. playersArchived[id].yPos .. " " .. playersArchived[id].zPos
			end

			teleport(cmd, chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_HealPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}heal {player name}"
			help[2] = "Apply big firstaid buff to a player or yourself if no name given."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "heal,play,buff"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "heal") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "heal") then
			if locations["heal"] then
				botman.faultyChat = false
				return false
			end

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

			if tonumber(server.gameVersionNumber) >= 17 then
				message(string.format("pm %s [%s]This command is for A16 only.", chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now so get your filthy ape hands off them![-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now so get your filthy ape hands off them!")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-buffplayer " .. id .. " firstAid") -- Pills here!
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You gave " .. players[id].name .. " firstaid.[-]")
			else
				irc_chat(chatvars.ircAlias, "You gave " .. players[id].name .. " firstaid.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_HordeMe() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}hordeme"
			help[2] = "Spawn a horde of 50 random zombies on yourself.  Only admins can do this (but not mods)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "spawn,horde"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "horde") or string.find(chatvars.command, "spawn"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "hordeme") or (chatvars.words[1] == "hordme") or (string.find(chatvars.command, "this is sparta")) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is not available from IRC. Use it ingame.")
				botman.faultyChat = false
				return true
			end

			for i=1,50,1 do
				cmd = "se " .. players[chatvars.playerid].id .. " " .. PicknMix()
				if botman.dbConnected then conn:execute("INSERT INTO gimmeQueue (steam, command) VALUES (" .. chatvars.playerid .. ",'" .. cmd .. "')") end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_KickPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}kick {Player name|Steam ID|Game ID} reason {optional reason}"
			help[2] = "Is Joe annoying you?  Kick his ass right out of the server! >:D"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "kick,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "kick"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "kick" and chatvars.words[2] ~= nil) then
			local playerName

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

			reason = "An admin kicked you."

			if string.find(chatvars.command, " reason ") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "kick ") + 5, string.find(chatvars.command, " reason") - 1)
				reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "reason ") + 7)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "kick ") + 5)
			end

			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if id ~= 0 then
					playerName = playersArchived[id].name
				end
			else
				playerName = players[id].name
			end

			if id == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName .. " is not on the server right now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName .. " is not on the server right now.")
				end

				botman.faultyChat = false
				return true
			end

			if accessLevel(id) > 2 then
				kick(id, reason)
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I won't kick staff.  :O[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}leave claims {player name}"
			help[2] = "Stop the bot automatically removing a player's claims.  They will still be removed if they are in a location that doesn't allow player claims."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "claim,key,lcb"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "leave" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
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

			pname = chatvars.words[3]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if id ~= 0 then
				-- this player's claims will not be removed unless in a reset zone and not staff
				if not isArchived then
					players[id].removeClaims = false
					if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 0 WHERE steam = " .. id) end
				else
					playersArchived[id].removeClaims = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET removeClaims = 0 WHERE steam = " .. id) end
				end

				if botman.dbConnected then conn:execute("UPDATE keystones SET remove = 0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName .. "'s claims will not be removed unless found in reset zones (if not staff).[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. "'s claims will not be removed unless found in reset zones (if not staff)")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBadItems()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bad items"
			help[2] = "List the items that are not allowed in player inventories and what action is taken."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,bad,item"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "bad" and chatvars.words[2] == "items") or (chatvars.words[1] == "list" and chatvars.words[2] == "bad" and chatvars.words[3] == "items") then
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

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these bad items in inventory:[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item -> Action[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these bad items in inventory:")
				irc_chat(chatvars.ircAlias, "Item -> Action")
			end

			for k, v in pairs(badItems) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. " -> " .. v.action  .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " -> " .. v.action)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBasesNearby()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}bases/homes\n"
			help[1] = help[1] .. " {#}bases/homes range {number}\n"
			help[1] = help[1] .. " {#}bases/homes near {player name} range {number}"
			help[2] = "See what player bases are nearby.  You can use it on yourself or on a player.  Range and player are optional.  The default range is 200 metres."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,range,near"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "home") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "bases" or chatvars.words[1] == "homes") then
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

			alone = true
			if (chatvars.number == nil) then chatvars.number = 201 end

			if (not string.find(chatvars.command, "range")) and (not string.find(chatvars.command, "near")) then
				for k, v in pairs(players) do
					if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
						dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.homeX, v.homeZ)

						if dist < tonumber(chatvars.number) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "   base 1   distance  " .. string.format("%-8.2d", dist) .. "[-]")
							alone = false
						end
					end

					if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
						dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.home2X, v.home2Z)

						if dist < tonumber(chatvars.number) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "   base 2   distance  " .. string.format("%-8.2d", dist) .. "[-]")
							alone = false
						end
					end
				end

				if (alone == true) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of you.")
				end
			else
				if string.find(chatvars.command, "range") then
					name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5, string.find(chatvars.command, "range") - 1)
					chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
				else
					name1 = string.sub(chatvars.command, string.find(chatvars.command, "near") + 5)
				end

				if string.find(chatvars.command, "nearby") then
					id = chatvars.playerid
				else
					name1 = string.trim(name1)
					id = LookupPlayer(name1)
				end

				if id == 0 then
					id = LookupArchivedPlayer(name1)

					if not (id == 0) then
						playerName = playersArchived[id].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. name1 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. name1)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[id].name
					isArchived = false
				end

				if (id ~= 0) then
					for k, v in pairs(players) do
						if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
							if not isArchived then
								dist = distancexz(players[id].xPos, players[id].zPos, v.homeX, v.homeZ)
							else
								dist = distancexz(playersArchived[id].xPos, playersArchived[id].zPos, v.homeX, v.homeZ)
							end

							if dist < tonumber(chatvars.number) then
								if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. playerName .. " are:[-]") end

								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "   base 1   distance  " .. string.format("%-8.2d", dist) .. "[-]")
								alone = false
							end
						end

						if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
							if not isArchived then
								dist = distancexz(players[id].xPos, players[id].zPos, v.home2X, v.home2Z)
							else
								dist = distancexz(playersArchived[id].xPos, playersArchived[id].zPos, v.home2X, v.home2Z)
							end

							if dist < tonumber(chatvars.number) then
								if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. playerName .. " are:[-]") end

								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. "   base 2   distance  " .. string.format("%-8.2d", dist) .. "[-]")
								alone = false
							end
						end
					end

					if (alone == true) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of " .. playerName .. "[-]")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBlacklist()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list blacklist"
			help[2] = "List the countries that are not allowed to play on the server."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "view,list,black,coun"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "list" and chatvars.words[2] == "blacklist") then
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

			if server.blacklistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These countries are blacklisted: " .. server.blacklistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are blacklisted: " .. server.blacklistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No countries are blacklisted.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}claims {range} (range is optional and defaults to 50)"
			help[2] = "List all of the claims within range with who owns them"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "view,list,claim,lcb,keys"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "claims") then
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

			if chatvars.number == nil then
				chatvars.number = 50
			end

			if botman.dbConnected then
				cursor,errorString = conn:execute("SELECT * FROM keystones WHERE abs(x - " .. chatvars.intX .. ") <= " .. chatvars.number .. " AND abs(z - " .. chatvars.intZ .. ") <= " .. chatvars.number)
				row = cursor:fetch({}, "a")
				while row do
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " " .. row.x .. " " .. row.y .. " " .. row.z .. "[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}offline players nearby\n"
			help[1] = help[1] .. " {#}offline players nearby range {number}"
			help[2] = "List all offline players near your position. The default range is 200 metres."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "offl,play,near,range"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "offline") or string.find(chatvars.command, "player") or string.find(chatvars.command, "near"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "offline" and chatvars.words[2] == "players" and chatvars.words[3] == "nearby") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			chatvars.number = 201

			if string.find(chatvars.command, "range") then
				chatvars.number = string.sub(chatvars.command, string.find(chatvars.command, "range") + 6)
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]offline players within " .. chatvars.number .. " meters of you are:[-]")

			alone = true
			count = 0

			for k, v in pairs(players) do
				if igplayers[k] == nil and v.xPos ~= nil then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.xPos, v.zPos)
					dist = math.abs(dist)

					if tonumber(dist) <= tonumber(chatvars.number) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. "[-]")
						alone = false
						count = count + 1
					end
				end

				if count > 30 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Too many results. Command aborted.[-]")

					botman.faultyChat = false
					return true
				end
			end

			if (alone == true) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No offline players within range.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListPrisoners()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}prisoners"
			help[2] = "List all the players who are prisoners."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,view,prison"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "prisoners" and chatvars.words[2] == nil) then
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

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]List of prisoners:[-]")
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

					if tonumber(v.pvpVictim) == 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " " .. tmp.reason .. "[-]")
						else
							irc_chat(chatvars.ircAlias, v.name .. " " .. tmp.reason)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " PVP " .. players[v.pvpVictim].name .. "[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}restricted items"
			help[2] = "List the items that new players are not allowed to have in inventory and what action is taken."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,view,rest,item"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "restricted" and chatvars.words[2] == "items") then
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

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these restricted items in inventory:[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item      Quantity      Min Access Level[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these restricted items in inventory:")
				irc_chat(chatvars.ircAlias, "Item.........Quantity..........Min Access Level")
			end

			for k, v in pairs(restrictedItems) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. " max qty " .. v.qty .. " min access " .. v.accessLevel .. " action " .. v.action)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListStaff()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list staff/admins"
			help[2] = "Lists the server staff and shows who if any are playing."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,staff,admin"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "list" and (chatvars.words[2] == "staff" or chatvars.words[2] == "admins") or (chatvars.words[1] == "admins" or chatvars.words[1] == "staff") and chatvars.words[3] == nil) then
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

			listStaff(chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListWhitelist()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list whitelist"
			help[2] = "List the countries that are allowed to play on the server."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,white,coun"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "list" and chatvars.words[2] == "whitelist") then
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

			if server.whitelistCountries ~= "" then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]These countries are whitelisted: " .. server.whitelistCountries .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "These countries are whitelisted: " .. server.whitelistCountries)
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No countries are whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, "No countries are whitelisted.")
				end
			end

			counter = 0
			for k,v in pairs(whitelist) do
				if counter == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The following players are whitelisted:[-]")
					else
						irc_chat(chatvars.ircAlias, ".")
						irc_chat(chatvars.ircAlias, "The following players are whitelisted:")
					end

					counter = counter + 1
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[k].name .. " - " .. players[k].country .. "[-]")
				else
					irc_chat(chatvars.ircAlias, players[k].name .. " - " .. players[k].country)
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LoadBotmanINI()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}load botman ini"
			help[2] = "Make the bot reload the botman.ini file.  It only reloads when told to."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "load,bot,ini"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ini"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "load" and chatvars.words[2] == "botman" and chatvars.words[3] == "ini" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			readBotmanINI()

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The botman.ini file has been read.[-]")
			else
				irc_chat(chatvars.ircAlias, "The botman.ini file has been read.")
			end

			botman.faultyChat = false
			result = true
		end
	end


	local function cmd_MendPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}mend {player name}"
			help[2] = "Remove the brokenLeg buff from a player or yourself if no name given."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "mend,fix,leg,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mend") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "mend") then
			if locations["mend"] then
				botman.faultyChat = false
				return false
			end

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

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and can't catch a break.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and can't catch a break.")
				end

				botman.faultyChat = false
				return true
			end


			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-debuffplayer " .. id .. " sprainedLeg")
				sendCommand("bc-debuffplayer " .. id .. " brokenLeg")
			else
				sendCommand("bc-debuffplayer " .. id .. " buffLegSprained")
				sendCommand("bc-debuffplayer " .. id .. " buffLegBroken")
				sendCommand("bc-debuffplayer " .. id .. " buffLegSplinted")
				sendCommand("bc-debuffplayer " .. id .. " buffLegCast")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You fixed " .. players[id].name .. "'s legs[-]")
			else
				irc_chat(chatvars.ircAlias, "You fixed " .. players[id].name .. "'s legs")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MovePlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}move {player name} to {location}"
			help[2] = "Teleport a player to a location. To teleport them to another player use the send command.  If the player is offline, they will be moved to the location when they next join."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "move,play,loca"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "move") and chatvars.words[2] ~= nil and string.find(chatvars.command, " to ") then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, "move") + 5, string.find(chatvars.command, " to ") - 1)
			pname = string.trim(pname)

			location = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
			location = string.trim(location)

			loc = LookupLocation(location)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if loc == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No location matched.[-]")
				else
					irc_chat(chatvars.ircAlias, "No location matched.")
				end

				botman.faultyChat = false
				return true
			end

			-- if the player is ingame, send them to the lobby otherwise flag it to happen when they rejoin
			if (igplayers[id]) then
				cmd = "tele " .. id .. " " .. locations[loc].x .. " " .. locations[loc].y .. " " .. locations[loc].z
				igplayers[id].lastTP = cmd
				teleport(cmd, id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been sent to " .. locations[loc].name .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " has been sent to " .. locations[loc].name)
				end
			else
				if not isArchived then
					players[id].location = loc
					if botman.dbConnected then conn:execute("UPDATE players SET location = '" .. loc .. "' WHERE steam = " .. id) end

					players[id].xPosOld = locations[loc].x
					players[id].yPosOld = locations[loc].y
					players[id].zPosOld = locations[loc].z
				else
					playersArchived[id].location = loc
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET location = '" .. loc .. "' WHERE steam = " .. id) end

					playersArchived[id].xPosOld = locations[loc].x
					playersArchived[id].yPosOld = locations[loc].y
					playersArchived[id].zPosOld = locations[loc].z
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName .. " will be moved to " .. locations[loc].name .. " next time they join.[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}near {player name} {optional number (distance away from player)}"
			help[2] = "Teleport below and a short distance away from a player.  You must be flying for this or you will just fall all the time.\n"
			help[2] = help[2] .. "You arrive 20 metres below the player and 30 metres to the south.  If you give a number after the player name you will be that number metres south of them.\n"
			help[2] = help[2] .. "The bot will keep you near the player, teleporting you close to them if they get away from you.\n"
			help[2] = help[2] .. "To stop following them type {#}stop or use any teleport command or relog."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "goto,play,near"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "near") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "closeto" or chatvars.words[1] == "near") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			if (players[chatvars.playerid].timeout or players[chatvars.playerid].botTimeout) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot go anywhere until you are released for safety reasons.[-]")
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
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				isArchived = false
			end

			igplayers[chatvars.playerid].following = id

			-- then teleport close to the player
			if not isArchived then
				if igplayers[id] then
					cmd = "tele " .. chatvars.playerid .. " " .. igplayers[id].xPos .. " " .. igplayers[id].yPos - 20 .. " " .. igplayers[id].zPos - igplayers[chatvars.playerid].followDistance
				else
					cmd = "tele " .. chatvars.playerid .. " " .. players[id].xPos .. " " .. players[id].yPos - 20 .. " " .. players[id].zPos - igplayers[chatvars.playerid].followDistance
				end
			else
				cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[id].xPos .. " " .. playersArchived[id].yPos - 20 .. " " .. playersArchived[id].zPos - igplayers[chatvars.playerid].followDistance
			end

			sendCommand(cmd)
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayerIsNotNew()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}player {player name} is not new"
			help[2] = "Upgrade a new player to a regular without making them wait for the bot to upgrade them. They will no longer be as restricted as a new player."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "play,new,status,upg"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "new") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "player" and string.find(chatvars.command, "is not new")) then
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

			pname = chatvars.words[2]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if id ~= 0 then
				-- set the newPlayer flag to false
				if not isArchived then
					players[id].newPlayer = false
					players[id].watchPlayer = false
					players[id].watchPlayerTimer = 0
					if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id) end
				else
					playersArchived[id].newPlayer = false
					playersArchived[id].watchPlayer = false
					playersArchived[id].watchPlayerTimer = 0
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id) end
				end

				message("say [" .. server.chatColour .. "]" .. playerName .. " is no longer new here. Welcome back " .. playerName .. "! =D[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PootaterPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}poop {player name}"
			help[2] = "Make a player shit potatoes everywhere coz potatoes."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "poo,play,buff,pot"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "poo") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "poop") then
			if locations["poop"] then -- There's a location called poop?  AWESOME!
				botman.faultyChat = false
				return false
			end

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and can't catch shit.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and can't catch shit.")
				end

				botman.faultyChat = false
				return true
			end

			if accessLevel(id) < 3 then
				message("pm " .. id .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " cast poop on you.  It is super effective.[-]")
			end

			r = rand(30,10)

			message("say [" .. server.chatColour .. "]" .. players[id].name .. " ate a bad potato and is shitting potatoes everywhere![-]")

			for i = 1, r do
				cmd = "give " .. id .. " potato 1"
				conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. cmd .. "', " .. id .. ")")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Boil em, mash em, stick em in " .. players[id].name .. ".[-]")
			else
				irc_chat(chatvars.ircAlias, "Boil em, mash em, stick em in " .. players[id].name)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReadClaims()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}read claims"
			help[2] = "Make the bot run llp so it knows where all the claims are and who owns them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "read,claim,lcb,key"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "read claims")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "read" and chatvars.words[2] == "claims" then
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

			-- run llp
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading claims[-]")
			sendCommand("llp parseable")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}release {player name}\n"
			help[1] = help[1] .. " {#}just release {player name}"
			help[2] = "Release a player from prison.  They are teleported back to where they were arrested.\n"
			help[2] = help[2] .. "Alternatively just release them so they do not teleport and have to walk back or use bot commands.\n"
			help[2] = help[2] .. "See also {#}release here (admin only)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "rele,free,priso,play"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prison") or string.find(chatvars.command, "releas"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "release" or (chatvars.words[1] == "just" and chatvars.words[2] == "release")) then
			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "release ") + 8)
			prisoner = string.trim(prisoner)
			prisonerid = LookupPlayer(prisoner)
			prisoner = players[prisonerid].name

			if prisonerid == 0 then
				prisonerid = LookupArchivedPlayer(prisoner)

				if not (prisonerid == 0) then
					playerName = playersArchived[prisonerid].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[prisonerid].name
				isArchived = false
			end

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					if (prisonerid == chatvars.playerid) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can't release yourself.  This isn't Idiocracy (except in Florida and Texas).[-]")
						botman.faultyChat = false
						return true
					end

					if not isArchived then
						if (players[prisonerid].pvpVictim ~= chatvars.playerid) then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
							botman.faultyChat = false
							return true
						end
					else
						if (playersArchived[prisonerid].pvpVictim ~= chatvars.playerid) then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
							botman.faultyChat = false
							return true
						end
					end
				end
			end

			if (players[prisonerid].timeout or players[prisonerid].botTimeout) then
				if not isArchived then
					players[prisonerid].timeout = false
					players[prisonerid].botTimeout = false
					players[prisonerid].freeze = false
					players[prisonerid].silentBob = false
					gmsg(server.commandPrefix .. "return " .. prisonerid)
					setChatColour(prisonerid)

					if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0 WHERE steam = " .. prisonerid) end
				else
					playersArchived[prisonerid].timeout = false
					playersArchived[prisonerid].botTimeout = false
					playersArchived[prisonerid].freeze = false
					playersArchived[prisonerid].silentBob = false

					if botman.dbConnected then conn:execute("UPDATE playersArchived SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0 WHERE steam = " .. prisonerid) end
				end
			end

			if (not players[prisonerid].prisoner and players[prisonerid].timeout == false) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Citizen " .. prisoner .. " is not a prisoner[-]")
				else
					irc_chat(chatvars.ircAlias, "Citizen " .. prisoner .. " is not a prisoner")
				end

				botman.faultyChat = false
				return true
			end

			if (igplayers[prisonerid]) then
				message("say [" .. server.warnColour .. "]Prisoner " .. prisoner .. " has been pardoned.[-]")
				message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")

				if (chatvars.words[1] ~= "just") then
					if (players[prisonerid].prisonxPosOld) then
						cmd = "tele " .. prisonerid .. " " .. players[prisonerid].prisonxPosOld .. " " .. players[prisonerid].prisonyPosOld .. " " .. players[prisonerid].prisonzPosOld
						igplayers[prisonerid].lastTP = cmd
						teleport(cmd, prisonerid)
					end
				else
					message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are a free citizen, but you must find your own way back.[-]")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 0, silentBob = 0, xPosOld = " .. players[prisonerid].prisonxPosOld .. ", yPosOld = " .. players[prisonerid].prisonyPosOld .. ", zPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid) end
			else
				if not isArchived then
					if (players[prisonerid]) then
						players[prisonerid].location = "return player"
						message("say [" .. server.chatColour .. "]" .. players[prisonerid].name .. " will be released when they next join the server.[-]")

						players[prisonerid].xPosOld = players[prisonerid].prisonxPosOld
						players[prisonerid].yPosOld = players[prisonerid].prisonyPosOld
						players[prisonerid].zPosOld = players[prisonerid].prisonzPosOld

						if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. players[prisonerid].prisonxPosOld .. ", yPosOld = " .. players[prisonerid].prisonyPosOld .. ", zPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid)  end
					end
				else
					if (playersArchived[prisonerid]) then
						playersArchived[prisonerid].location = "return player"
						message("say [" .. server.chatColour .. "]" .. playersArchived[prisonerid].name .. " will be released when they next join the server.[-]")

						playersArchived[prisonerid].xPosOld = playersArchived[prisonerid].prisonxPosOld
						playersArchived[prisonerid].yPosOld = playersArchived[prisonerid].prisonyPosOld
						playersArchived[prisonerid].zPosOld = playersArchived[prisonerid].prisonzPosOld

						if botman.dbConnected then conn:execute("UPDATE playersArchived SET prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. playersArchived[prisonerid].prisonxPosOld .. ", yPosOld = " .. playersArchived[prisonerid].prisonyPosOld .. ", zPosOld = " .. playersArchived[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid) end
					end
				end
			end

			if not isArchived then
				players[prisonerid].xPosOld = 0
				players[prisonerid].yPosOld = 0
				players[prisonerid].zPosOld = 0
				players[prisonerid].prisoner = false
				players[prisonerid].prisonReason = ""
				players[prisonerid].silentBob = false
				players[prisonerid].prisonReleaseTime = os.time()
				setChatColour(prisonerid)
			else
				playersArchived[prisonerid].xPosOld = 0
				playersArchived[prisonerid].yPosOld = 0
				playersArchived[prisonerid].zPosOld = 0
				playersArchived[prisonerid].prisoner = false
				playersArchived[prisonerid].prisonReason = ""
				playersArchived[prisonerid].silentBob = false
				playersArchived[prisonerid].prisonReleaseTime = os.time()
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayerHere()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}release here {prisoner}"
			help[2] = "Release a player from prison and move them to your location."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "real,free,priso,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rele") or string.find(chatvars.command, "free") or string.find(chatvars.command, "pris"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "release" and chatvars.words[2] == "here" and chatvars.words[3] ~= nil) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			prisoner = string.sub(chatvars.command, string.find(chatvars.command, ": " .. server.commandPrefix .. "release here ") + 16)
			prisoner = string.trim(prisoner)
			prisonerid = LookupPlayer(prisoner)

			if prisonerid == 0 then
				prisonerid = LookupArchivedPlayer(prisoner)

				if not (prisonerid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end

					botman.faultyChat = false
					return true
				end
			end

			if (players[prisonerid].prisoner == false) then
				message("say [" .. server.chatColour .. "]Citizen " .. players[prisonerid].name .. " is not a prisoner[-]")
				botman.faultyChat = false
				return true
			end

			if igplayers[prisonerid] then
				if players[prisonerid].chatColour ~= "" then
					setPlayerColour(prisonerid, players[prisonerid].chatColour)
				else
					setChatColour(prisonerid)
				end

				if botman.dbConnected then conn:execute("UPDATE players SET prisoner=0,timeout=0,botTimeout=0,silentBob=0 WHERE steam = " .. prisonerid) end

				players[prisonerid].prisoner = false
				players[prisonerid].timeout = false
				players[prisonerid].botTimeout = false
				players[prisonerid].freeze = false
				players[prisonerid].silentBob = false
				players[prisonerid].prisonReason = ""
				players[prisonerid].prisonReleaseTime = os.time()

				message("say [" .. server.chatColour .. "]Releasing prisoner " .. playerName .. "[-]")
				message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")

				cmd = "tele " .. prisonerid .. " " .. chatvars.playerid
				teleport(cmd, prisonerid)
				players[prisonerid].xPosOld = 0
				players[prisonerid].yPosOld = 0
				players[prisonerid].zPosOld = 0
				players[prisonerid].prisonxPosOld = 0
				players[prisonerid].prisonyPosOld = 0
				players[prisonerid].prisonzPosOld = 0
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " is not on the server right now. Get them to rejoin the server and repeat this command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " is not on the server right now. Get them to rejoin the server and repeat this command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReloadAdmins()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reload admins"
			help[2] = "Make the bot run admin list to reload the admins from the server's list."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "real,free,priso,play"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload admins")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "admins" then
			-- run admin list
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading admin list[-]")
			sendCommand("admin list")
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemovePlayerClaims()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove claims {player name}"
			help[2] = "The bot will automatically remove the player's claims whenever possible. The chunk has to be loaded and the bot takes several minutes to remove them but it will remove them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "remo,claim,key,lcb"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "remove" and chatvars.words[2] == "claims" and chatvars.words[3] ~= nil) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			pname = chatvars.words[3]
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if id ~= 0 then
				-- flag the player's claims for removal
				if not isArchived then
					players[id].removeClaims = true
					if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 1 WHERE steam = " .. id) end
				else
					playersArchived[id].removeClaims = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET removeClaims = 1 WHERE steam = " .. id) end
				end

				if botman.dbConnected then conn:execute("UPDATE keystones SET remove = 1 WHERE steam = " .. id) end

				if accessLevel(id) > 2 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName .. "'s claims will be removed when players are nearby.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName .. "'s claims will be removed when players are nearby.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admin " .. playerName .. "'s claims will be marked for removal but will only be removed when they are no longer an admin (and not using {#}test as player).[-]")
					else
						irc_chat(chatvars.ircAlias, "Admin " .. playerName .. "'s claims will be marked for removal but will only be removed when they are no longer an admin (and not using {#}test as player).")
					end
				end

				-- do a scan now so all of their claims are recorded
				sendCommand("llp " .. id .. " parseable")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset player {player name}"
			help[2] = "Make the bot forget a player's cash, waypoints, bases etc but leave their donor status alone."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "reset,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
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

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 8)

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			resetPlayer(id)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " has been reset (in the bot's records).[-]")
			else
				irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " has been reset (in the bot's records)")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayerTimers()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}resettimers {player name}"
			help[2] = "Normally a player needs to wait a set time after {#}base before they can use it again. This zeroes that timer and also resets their gimmies."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "reset,time,cool,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "resettimers") then
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

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "resettimers ") + 12)

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if (players[id]) then
				players[id].baseCooldown = 0
				players[id].gimmeCount = 0

				if botman.dbConnected then conn:execute("UPDATE players SET baseCooldown = 0, gimmeCount = 0 WHERE steam = " .. id) end
			end

			message("say [" .. server.chatColour .. "]Cooldown timers have been reset for " .. players[id].name .. "[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetStackSizes()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset stack"
			help[2] = "If you have changed stack sizes and the bot is mistakenly abusing players for overstacking, you can make the bot forget the stack sizes.\n"
			help[2] = help[2] .. "It will re-learn them from the server as players overstack beyond the new stack limits."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "reset,clear,stack,size"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "stack"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "clear" or chatvars.words[1] == "reset") and chatvars.words[2] == "stack" then
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

			stackLimits = {}

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.[-]")
			else
				irc_chat(chatvars.ircAlias, "The bot's record of stack limits has been wiped.  It will re-learn them from the server as players overstack items.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RestoreAdmin()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}restore admin"
			help[2] = "Use this command if you have used {#}test as player, and you want to get your admin status back now."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "test,play,admin,rest"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rest") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		-- if chatvars.words[1] == "restore" and chatvars.words[2] == "admin" then
			-- if chatvars.ircid ~= 0 then
				-- if botman.dbConnected then conn:execute("UPDATE persistentQueue SET timerDelay = now() WHERE steam = " .. chatvars.ircid) end
			-- else
				-- if botman.dbConnected then conn:execute("UPDATE persistentQueue SET timerDelay = now() WHERE steam = " .. chatvars.playerid) end
			-- end

			-- botman.faultyChat = false
			-- return true
		-- end
	end


	local function cmd_ReturnPlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}return {player name}\n"
			help[1] = help[1] .. " {#}return {player name} to {location or other player}"
			help[2] = "Return a player from timeout.  You can use their steam or game id and part or all of their name.\n"
			help[2] = help[2] .. "You can return them to any player even offline ones or to any location. If you just return them, they will return to wherever they were when they were sent to timeout.\n"
			help[2] = help[2] .. "Your regular players can also return new players from timeout but only if a player sent them there."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "retu,play,time"
				tmp.accessLevel = 90
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "return")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "return" and chatvars.words[2] ~= nil) then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 90) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This command is restricted. Just type " .. server.commandPrefix .. "return.[-]")
					botman.faultyChat = false
					return true
				end
			end

			tmp = {}

			if string.find(chatvars.command, " to ") then
				tmp.loc = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)
				tmp.loc = string.trim(tmp.loc)
				tmp.loc = LookupLocation(tmp.loc)

				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7, string.find(chatvars.command, " to ") - 1)
				tmp.pname = string.trim(tmp.pname)
				tmp.id = LookupPlayer(tmp.pname)
			else
				tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "return ") + 7)
				tmp.pname = string.trim(tmp.pname)
				tmp.id = LookupPlayer(tmp.pname)
			end

			if tmp.id == 0 then
				tmp.id = LookupArchivedPlayer(tmp.pname)

				if not (tmp.id == 0) then
					playerName = playersArchived[tmp.id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[tmp.id].name
				isArchived = false
			end

			if (chatvars.playername ~= "Server") then
				-- don't allow players to return anyone to a different location.
				if (chatvars.accessLevel > 2) then
					tmp.loc = nil
				end
			end

			if tmp.id == chatvars.playerid then
				if (players[tmp.id].timeout or players[tmp.id].botTimeout) and chatvars.accessLevel > 2 then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot release yourself.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if not isArchived then
				if (not players[tmp.id].timeout and not players[tmp.id].botTimeout) and players[tmp.id].prisoner and ((tmp.id ~= chatvars.playerid and chatvars.accessLevel > 2) or chatvars.playerid == players[id].pvpVictim) then
					gmsg(server.commandPrefix .. "release " .. tmp.id)
					botman.faultyChat = false
					return true
				end
			else
				if (not players[tmp.id].timeout and not players[tmp.id].botTimeout) and playersArchived[tmp.id].prisoner and ((tmp.id ~= chatvars.playerid and chatvars.accessLevel > 2) or chatvars.playerid == playersArchived[id].pvpVictim) then
					gmsg(server.commandPrefix .. "release " .. tmp.id)
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.playername ~= "Server") then
				if chatvars.accessLevel > 2 then
					if players[tmp.id] then
						if players[tmp.id].newPlayer == false or players[tmp.id].botTimeout == true then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only use this command on new players and only when the bot didn't put them there.[-]")
							botman.faultyChat = false
							return true
						end
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]That player has been archived. Ask them to join then repeat this command.[-]")
						botman.faultyChat = false
						return true
					end
				end
			end

			-- return player to previously recorded x y z
			if (igplayers[tmp.id]) then
				if players[tmp.id].timeout or players[tmp.id].botTimeout then
					players[tmp.id].timeout = false
					players[tmp.id].botTimeout = false
					players[tmp.id].freeze = false
					players[tmp.id].silentBob = false
					igplayers[tmp.id].skipExcessInventory = true

					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.id].name .. " to " .. tmp.loc)
						end
					else
						tmp.cmd = "tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " " .. players[tmp.id].yPosTimeout .. " " .. players[tmp.id].zPosTimeout

						if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id) end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.id].name)
						end
					end

					players[tmp.id].xPosTimeout = 0
					players[tmp.id].yPosTimeout = 0
					players[tmp.id].zPosTimeout = 0

					teleport(tmp.cmd, tmp.id)
				else
					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
						players[tmp.id].xPosOld = 0
						players[tmp.id].yPosOld = 0
						players[tmp.id].zPosOld = 0
						players[tmp.id].xPosOld2 = 0
						players[tmp.id].yPosOld2 = 0
						players[tmp.id].zPosOld2 = 0

						teleport(tmp.cmd, tmp.id)

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.id].name .. " to " .. tmp.loc)
						end
					else
						if tonumber(players[tmp.id].yPosOld) == 0 and tonumber(players[tmp.id].yPosOld2) == 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has no returns.[-]")
							else
								irc_chat(chatvars.ircAlias, players[tmp.id].name .. " has no returns.")
							end

							botman.faultyChat = false
							return true
						end

						if tonumber(players[tmp.id].yPosOld2) ~= 0 then
							-- the player has teleported within the same location so they are returning to somewhere in that location
							cmd = "tele " .. tmp.id .. " " .. players[tmp.id].xPosOld2 .. " " .. players[tmp.id].yPosOld2 .. " " .. players[tmp.id].zPosOld2
							teleport(cmd, tmp.id)

							players[tmp.id].xPosOld2 = 0
							players[tmp.id].yPosOld2 = 0
							players[tmp.id].zPosOld2 = 0

							conn:execute("UPDATE players SET xPosOld2 = 0, yPosOld2 = 0, zPosOld2 = 0 WHERE steam = " .. tmp.id)
						else
							-- the player has teleported from outside their current location so they are returning to there.
							cmd = "tele " .. tmp.id .. " " .. players[tmp.id].xPosOld .. " " .. players[tmp.id].yPosOld .. " " .. players[tmp.id].zPosOld
							teleport(cmd, tmp.id)

							players[tmp.id].xPosOld = 0
							players[tmp.id].yPosOld = 0
							players[tmp.id].zPosOld = 0
							igplayers[tmp.id].lastLocation = ""

							conn:execute("UPDATE players SET xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = " .. tmp.id)
						end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "Returning " .. players[tmp.id].name)
						end
					end
				end

				botman.faultyChat = false
				return true
			else
				if not isArchived then
					if (players[tmp.id].yPosTimeout) then
						players[tmp.id].timeout = false
						players[tmp.id].botTimeout = false
						players[tmp.id].silentBob = false

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " will be returned when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, playerName .. " will be returned when they next join the server.")
						end

						if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = " .. tmp.id) end
					end
				else
					if (playersArchived[tmp.id].yPosTimeout) then
						playersArchived[tmp.id].timeout = false
						playersArchived[tmp.id].botTimeout = false
						playersArchived[tmp.id].silentBob = false

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " will be returned when they next join the server.[-]")
						else
							irc_chat(chatvars.ircAlias, playerName .. " will be returned when they next join the server.")
						end

						if botman.dbConnected then conn:execute("UPDATE playersArchived SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = " .. tmp.id) end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendPlayerHome()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}sendhome {player name}\n"
			help[1] = help[1] .. " {#}sendhome2 {player name}"
			help[2] = "Teleport a player to their first or second base."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "send,move,play,home,base,tele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "home") or string.find(chatvars.command, "player") or string.find(chatvars.command, "send"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "sendhome" or chatvars.words[1] == "sendhome2") then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, "sendhome") + 9)
			pname = string.trim(pname)

			if (pname == "") then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player name is required or could not be found for this command[-]")
				else
					irc_chat(chatvars.ircAlias, "A player name is required or could not be found for this command")
				end

				botman.faultyChat = false
				return true
			else
				id = 0
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No players found with that name.[-]")
						else
							irc_chat(chatvars.ircAlias, "No players found called " .. pname)
						end
					end

					botman.faultyChat = false
					return true
				end

				if (accessLevel(id) < 3 and id ~= chatvars.playerid) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be teleported by other staff.[-]")
					else
						irc_chat(chatvars.ircAlias, "Staff cannot be teleported by other staff.")
					end

					botman.faultyChat = false
					return true
				end

				if (players[id].timeout == true) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is in timeout. " .. server.commandPrefix .. "return them first[-]")
					else
						irc_chat(chatvars.ircAlias, players[id].name .. " is in timeout. Return them first.")
					end

					botman.faultyChat = false
					return true
				end

				-- first record the current x y z
				if (igplayers[id]) then
					players[id].xPosOld = igplayers[id].xPos
					players[id].yPosOld = igplayers[id].yPos
					players[id].zPosOld = igplayers[id].zPos
				end

				if (chatvars.words[1] == "sendhome") then
					if (players[id].homeX == 0 and players[id].homeZ == 0) then
						if server.coppi or server.stompy then
							prepareTeleport(id, "")
							sendPlayerHome(id)

							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent to their bed.[-]")
							else
								irc_chat(chatvars.ircAlias, players[id].name .. " has been sent to their bed.")
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a base yet.[-]")
							else
								irc_chat(chatvars.ircAlias, players[id].name .. " has not set a base yet.")
							end
						end

						botman.faultyChat = false
						return true
					else
						if (igplayers[id]) then
							cmd = "tele " .. id .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
							teleport(cmd, id)
						end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
						else
							irc_chat(chatvars.ircAlias, players[id].name .. " has been sent home.")
						end
					end
				else
					if (players[id].home2X == 0 and players[id].home2Z == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has not set a 2nd base yet.[-]")
						else
							irc_chat(chatvars.ircAlias, players[id].name .. " has not set a 2nd base yet.")
						end

						botman.faultyChat = false
						return true
					else
						if (igplayers[id]) then
							cmd = "tele " .. id .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
							teleport(cmd, id)
						end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been sent home")
						else
							irc_chat(chatvars.ircAlias, players[id].name .. " has been sent home.")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendPlayerToPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}send {player} to {other player}"
			help[2] = "Teleport a player to another player even if the other player is offline."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "send,move,play,tele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "send") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "send") then
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

			pname1 = string.sub(chatvars.command, 7, string.find(chatvars.command, " to ") - 1)
			pname2 = string.sub(chatvars.command, string.find(chatvars.command, " to ") + 4)

			id1 = LookupPlayer(pname1)
			id2 = LookupPlayer(pname2)

			if id1 == 0 then
				id1 = LookupArchivedPlayer(pname1)

				if not (id1 == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id1].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id1].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname1 .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname1 .. " did not match any players.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if id2 == 0 then
				id2 = LookupArchivedPlayer(pname2)

				if not (id2 == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id2].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id2].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname2 .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname2 .. " did not match any players.")
					end
				end

				botman.faultyChat = false
				return true
			end

			if (accessLevel(id1) < 3) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be teleported by other staff.[-]")
				else
					irc_chat(chatvars.ircAlias, "Staff cannot be teleported by other staff.")
				end

				botman.faultyChat = false
				return true
			end

			if not igplayers[id1] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id1].name .. " is not on the server right now.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id1].name .. " is not on the server right now.")
				end

				botman.faultyChat = false
				return true
			end

			if (id ~= 0 and id2 ~= 0) then
				if (players[id1].timeout == true) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id1].name .. " is in timeout. Return them first[-]")
					else
						irc_chat(chatvars.ircAlias, players[id1].name .. " is in timeout. Return them first.")
					end

					botman.faultyChat = false
					return true
				end

				-- first record the current x y z
				players[id1].xPosOld = players[id1].xPos
				players[id1].yPosOld = players[id1].yPos
				players[id1].zPosOld = players[id1].zPos

				if (igplayers[id2]) then
					cmd = "tele " .. id1 .. " " .. id2
					teleport(cmd, id1)
				else
					cmd = "tele " .. id1 .. " " .. players[id2].xPos .. " " .. players[id2].yPos .. " " .. players[id2].zPos
					teleport(cmd, id1)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetDropMiningWarningThreshold()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set drop mining warning {number of blocks} (default is 99)"
			help[2] = "Set how many blocks can fall off the world every minute before the bot alerts admins to it.\n"
			help[2] = help[2] .. "Disable by setting it to 0"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,drop,mining,alert,warn"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "drop") or string.find(chatvars.command, "mining") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "set drop mining warning") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			server.dropMiningWarningThreshold = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET dropMiningWarningThreshold = " .. server.dropMiningWarningThreshold) end

			if server.dropMiningWarningThreshold > 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will alert admins to drop mining over " .. server.dropMiningWarningThreshold .. " blocks dropped per minute.[-]")
				else
					message("say [" .. server.chatColour .. "]The bot will alert admins to drop mining over " .. server.dropMiningWarningThreshold .. " blocks dropped per minute.[-]")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not alert on drop mining.[-]")
				else
					message("say [" .. server.chatColour .. "]The bot will not alert on drop mining.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetCommandCooldown()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set command cooldown {seconds} (default 0)"
			help[2] = "You can add a delay between player commands to the bot.  Does not apply to staff.  This helps to slow down command abuse."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,comm,cool,delay"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "command") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "command" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set return cooldown 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set return cooldown 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.commandCooldown = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET commandCooldown = " .. server.commandCooldown) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. server.commandCooldown .. " seconds between commands to the bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. server.commandCooldown .. " seconds between commands to the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetFeralHordeNight()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set feral horde night {day number} (default is 7)"
			help[2] = "Set which day is horde night.  This is needed if your horde nights are not every 7 days."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,feral,horde,night"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "feral") or string.find(chatvars.command, "night") or string.find(chatvars.command, "day"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.command == "feral horde night") then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Horde nights happen every " .. server.hordeNight .. " days.[-]")
			else
				message("say [" .. server.chatColour .. "]Horde nights happen every " .. server.hordeNight .. " days.[-]")
			end

			botman.faultyChat = false
			return true
		end

		if string.find(chatvars.command, "set feral horde night") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			server.hordeNight = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET hordeNight = " .. server.hordeNight) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot now calculates horde nights as happening every " .. server.hordeNight .. " days.[-]")
			else
				message("say [" .. server.chatColour .. "]The bot now calculates horde nights as happening every " .. server.hordeNight .. " days.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetFeralRebootDelay()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}feral reboot delay {minutes}"
			help[2] = "Set how many minutes after day 7 that the bot will wait before rebooting if a reboot is scheduled for day 7.\n"
			help[2] = help[2] .. "To disable this feature, set it to 0.  The bot will wait a full game day instead."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,feral,reboo,time,delay"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "feral") or string.find(chatvars.command, "rebo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "feral" and chatvars.words[2] == "reboot" and chatvars.words[3] == "delay") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			server.feralRebootDelay = math.abs(math.floor(chatvars.number))
			if botman.dbConnected then conn:execute("UPDATE server SET feralRebootDelay = " .. server.feralRebootDelay) end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
			else
				message("say [" .. server.chatColour .. "]Reboots that fall on a feral day will happen " .. server.feralRebootDelay .. " minutes into the next day.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxTrackingDays()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}max tracking days {days}"
			help[2] = "Set how many days to keep tracking data before deleting it.  The default it 28."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,max,day,track,log"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "log") or string.find(chatvars.command, "track") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "max tracking days") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			if chatvars.number then
				if chatvars.number == 0 then
					server.trackingKeepDays = 0
					conn:execute("UPDATE server SET trackingKeepDays = 0")

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Automatic database maintenance is disabled.  Good luck.", chatvars.playerid, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Automatic database maintenance is disabled.  Good luck.")
					end
				else
					chatvars.number = math.abs(chatvars.number)
					server.trackingKeepDays = chatvars.number
					conn:execute("UPDATE server SET trackingKeepDays = " .. chatvars.number)

					if (chatvars.playername ~= "Server") then
						message(string.format("pm %s [%s]Tracking data older than " .. chatvars.number .. " days will be deleted daily at midnight server time.", chatvars.playerid, server.chatColour))
					else
						irc_chat(chatvars.ircAlias, "Tracking data older than " .. chatvars.number .. " days will be deleted daily at midnight server time.")
					end
				end
			else
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]A number is required. Setting it beyond 28 days is not recommended.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "A number is required. Setting it beyond 28 days is not recommended.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetReservedSlotTimelimit()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set reserved slot timelimit {minutes} (default 0)"
			help[2] = "If this is 0, reserved slots are released when the player leaves the server.\n"
			help[2] = help[2] .. "Otherwise minutes after the player reserves a slot, they will become eligible to be kicked to make room for another reserved slotter."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,reser,slot,time"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, " set") or string.find(chatvars.command, "slot") or string.find(chatvars.command, "reser") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.command, "set reserved slot time") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set reserved slot time 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set reserved slot time 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.reservedSlotTimelimit = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET reservedSlotTimelimit = " .. server.reservedSlotTimelimit) end

				if reservedSlotTimelimit == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players who are authorised to reserve slots will hold them until they leave the server.[-]")
					else
						irc_chat(chatvars.ircAlias, "Players who are authorised to reserve slots will hold them until they leave the server.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.reservedSlotTimelimit .. " minutes after an authorised player starts using a reserved slot, they can be kicked if another authorised player joins and the server is full.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set return cooldown {seconds} (default 0)"
			help[2] = "You can add a delay to the return command.  Does not affect staff."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,retu,time,cool,delay"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "return") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "return" and (chatvars.words[3] == "cooldown" or chatvars.words[3] == "delay" or chatvars.words[3] == "timer") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required eg. " .. server.commandPrefix .. "set return cooldown 10[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required  eg. " .. server.commandPrefix .. "set return cooldown 10")
				end
			else
				chatvars.number = math.abs(chatvars.number)

				server.returnCooldown = chatvars.number
				if botman.dbConnected then conn:execute("UPDATE server SET returnCooldown = " .. server.returnCooldown) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must wait " .. server.returnCooldown .. " seconds after teleporting before they can use the " .. server.commandPrefix .. "return command.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players must wait " .. server.returnCooldown .. " seconds after teleporting before they can use the " .. server.commandPrefix .. "return command.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetViewArrestReason() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}prisoner {player name} arrested {reason for arrest}\n"
			help[1] = help[1] .. " {#}prisoner {player name} (read the reason if one is recorded)"
			help[2] = "You can record or view the reason for a player being arrested.  If they are released, this record is destroyed."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,view,arrest,reason"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prisoner") or string.find(chatvars.command, "arrest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "prisoner") then
			reason = nil

			if string.find(chatvars.command, "arrested") then
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9, string.find(chatvars.command, "arrested") -1)

				if chatvars.accessLevel < 3 then
					reason = string.sub(chatvars.commandOld, string.find(chatvars.command, "arrested ") + 9)
				end
			else
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9)
			end

			prisoner = stripQuotes(string.trim(prisoner))
			prisonerid = LookupPlayer(prisoner)

			if prisonerid == 0 then
				prisonerid = LookupArchivedPlayer(prisoner)

				if not (prisonerid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Command not available.  Player " .. playersArchived[prisonerid].name .. " is archived.[-]")
					else
						irc_chat(chatvars.ircAlias, "Command not available.  Player " .. playersArchived[prisonerid].name .. " is archived.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
					end
				end

				botman.faultyChat = false
				return true
			end

			prisoner = players[prisonerid].name

			if (prisonerid == 0 or not players[prisonerid].prisoner) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. prisoner .. " is not a prisoner[-]")
				else
					irc_chat(chatvars.ircAlias, prisoner .. " is not a prisoner.")
				end

				botman.faultyChat = false
				return true
			end

			if players[prisonerid].prisoner then
				if reason ~= nil and tonumber(chatvars.accessLevel) < 3 then
					players[prisonerid].prisonReason = reason
					if botman.dbConnected then conn:execute("UPDATE players SET prisonReason = '" .. escape(reason) .. "' WHERE steam = " .. prisonerid) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added a reason for prisoner " .. prisoner .. "'s arrest[-]")
					else
						irc_chat(chatvars.ircAlias, "Reason for prisoner " .. prisoner .. "'s arrest noted.")
					end
				else
					if players[prisonerid].prisonReason ~= nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " was arrested for " .. players[prisonerid].prisonReason .. "[-]")

							if players[prisonerid].bail > 0 then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bail is set at " .. players[prisonerid].bail .. " " .. server.moneyPlural .. "[-]")
							end
						else
							irc_chat(chatvars.ircAlias, prisoner .. " was arrested for " .. players[prisonerid].prisonReason)

							if players[prisonerid].bail > 0 then
								irc_chat(chatvars.ircAlias, "Bail is set at " .. players[prisonerid].bail .. " " .. server.moneyPlural)
							end
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] No reason is recorded for " .. prisoner .. "'s arrest.[-]")

							if players[prisonerid].bail > 0 then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bail is set at " .. players[prisonerid].bail .. " " .. server.moneyPlural .. "[-]")
							end
						else
							irc_chat(chatvars.ircAlias, "No reason is recorded for " .. prisoner .. "'s arrest.")

							if players[prisonerid].bail > 0 then
								irc_chat(chatvars.ircAlias, "Bail is set at " .. players[prisonerid].bail .. " " .. server.moneyPlural)
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set watch timer {number in seconds}"
			help[2] = "When a new player joins, in-game admins will be messaged when the player adds or removes inventory.  They will automatically stop being watched after a delay.  The default is 3 days.\n"
			help[2] = help[2] .. "You can also set a different watch duration for an individual player.\n"
			help[2] = help[2] .. "1 hour = 3,600  1 day = 86,400  1 week = 604,800  4 weeks = 2,419,200\n"
			help[2] = help[2] .. "This timer is in real time not game time or time played."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,watch,player,timer"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "watch") or string.find(chatvars.command, "inven"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "watch" and chatvars.words[3] == "timer" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.number ~= nil then
				chatvars.number = math.abs(chatvars.number)
			else
				chatvars.number = 259200 -- 3 days in seconds.  Time flies!
			end

			server.defaultWatchTimer = chatvars.number
			conn:execute("UPDATE server SET defaultWatchTimer = " .. chatvars.number)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A player's inventory will be reported live for " .. chatvars.number .. " seconds from when inventory watching starts for them.[-]")
			else
				irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShitPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}shit {player name}"
			help[2] = "Give a player the shits for shits and giggles."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "shit,play,buff"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shit") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "shit") then
			if locations["shit"] then
				botman.faultyChat = false
				return false
			end

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and can't catch shit.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and can't catch shit.")
				end

				botman.faultyChat = false
				return true
			end

			if accessLevel(id) < 3 then
				message("pm " .. id .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " cast shit on you.  It is super effective.[-]")
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-buffplayer " .. id .. " dysentery")
			else
				sendCommand("bc-givebuff " .. id .. " buffIllDysentery1")
			end


			if tonumber(server.gameVersionNumber) < 17 then
				r = rand(10)

				for i = 1, r do
					sendCommand("give " .. igplayers[id].id .. " turd 1")
				end

				message("pm " .. id .. " [" .. server.chatColour .. "]Hey " .. players[id].name .. "! You dropped something.[-]")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You showed " .. players[id].name .. " that you give a shit.[-]")
			else
				irc_chat(chatvars.ircAlias, "You showed " .. players[id].name .. " that you give a shit.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TestAsPlayer()
		local cmd, restoreDelay, pid

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}test as player {optional number in seconds}"
			help[2] = "Remove your admin status for 5 minutes.  After 5 minutes your admin status will be restored and any bans against you removed.\n"
			help[2] = help[2] .. "If you provide a number, your admin will instead be restored after that many seconds incase you need longer or shorter than the default 5 minutes."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "test,play,admin"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "test") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "test" and chatvars.words[2] == "as" and chatvars.words[3] == "player" then
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

			if chatvars.ircid ~= 0 then
				pid = chatvars.ircid
			else
				pid = chatvars.playerid
			end

			restoreDelay = 300

			if chatvars.number ~= nil then
				restoreDelay = math.abs(chatvars.number)
			end

			cmd = string.format("ban remove %s", pid)
			if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. pid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + restoreDelay) .. "')") end

			cmd = string.format("admin add %s %s", pid, chatvars.accessLevel)
			if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. pid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + restoreDelay) .. "')") end

			cmd = string.format("pm %s [%s]Your admin status is restored.[-]", pid, server.chatColour)
			if botman.dbConnected then conn:execute("insert into persistentQueue (steam, command, timerDelay) values (" .. pid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + restoreDelay) .. "')") end

			sendCommand("admin remove " .. pid)

			if (chatvars.playername ~= "Server") then
				message(string.format("pm %s [%s]Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck![-]", pid, server.chatColour))
			else
				irc_chat(chatvars.ircAlias, "Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck!")

				if igplayers[pid] then
					message(string.format("pm %s [%s]Your admin status has been temporarily removed.  You are now a player.  You will regain admin in " .. restoreDelay .. " seconds.  Good luck![-]", pid, server.chatColour))
				end
			end

			players[pid].testAsPlayer = true

			-- force an early retirement
			owners[pid] = nil
			admins[pid] = nil
			mods[pid] = nil
			players[pid].accessLevel = 90
			setChatColour(pid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TimeoutPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}timeout {player name}"
			help[2] = "Send a player to timeout.  You can use their steam or game id and part or all of their name.  If you send the wrong player to timeout {#}return {player name} to fix that.\n"
			help[2] = help[2] .. "While in timeout, the player will not be able to use any bot commands but they can chat."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "time,out,play,send,remo"
				tmp.accessLevel = 90
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "timeout")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "timeout") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 90) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[2] == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Send a player to timeout where they can only talk.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can also send yourself to timeout but not staff.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "timeout {player name}[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See also: " .. server.commandPrefix .. "return {player name}[-]")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "timeout ") + 8)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)

			if tmp.id == 0 then
				tmp.id = LookupArchivedPlayer(tmp.pname)

				if not (tmp.id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. tmp.pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. tmp.pname)
					end
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if (players[tmp.id].newPlayer == false and chatvars.accessLevel > 3) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are limited to sending new players to timeout. " .. players[tmp.id].name .. " is not new.[-]")
					botman.faultyChat = false
					return true
				end
			end

			if tmp.id == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if (players[tmp.id].timeout == true) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This player is already in timeout.  Did you mean " .. server.commandPrefix .. "return ?[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. tmp.id .. " " .. players[tmp.id].name .. " is already in timeout.")
				end

				botman.faultyChat = false
				return true
			end

			if (accessLevel(tmp.id) < 3 and botman.ignoreAdmins == true) and tmp.id ~= chatvars.playerid then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Staff cannot be sent to timeout.[-]")
				else
					irc_chat(chatvars.ircAlias, "Staff cannot be sent to timeout.")
				end

				botman.faultyChat = false
				return true
			end

			if accessLevel(tmp.id) > 2	then
				players[tmp.id].silentBob = true
			end

			-- first record their current x y z
			players[tmp.id].timeout = true
			players[tmp.id].xPosTimeout = players[tmp.id].xPos
			players[tmp.id].yPosTimeout = players[tmp.id].yPos
			players[tmp.id].zPosTimeout = players[tmp.id].zPos

			if (chatvars.playername ~= "Server") then
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.playerid].name) .. "'," .. tmp.id .. ")") end
			else
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.ircid].name) .. "'," .. tmp.id .. ")") end
			end

			-- then teleport the player to timeout
			sendCommand("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " 60000 " .. players[tmp.id].zPosTimeout)
			message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has been sent to timeout.[-]")

			if botman.dbConnected then conn:execute("UPDATE players SET timeout = 1, silentBob = 1, xPosTimeout = " .. players[tmp.id].xPosTimeout .. ", yPosTimeout = " .. players[tmp.id].yPosTimeout .. ", zPosTimeout = " .. players[tmp.id].zPosTimeout .. " WHERE steam = " .. tmp.id) end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleLevelHackAlert()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable level hack alert"
			help[2] = "By default the bot will inform admins when a player's level increases massively in a very short time.  You can disable the message."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,level,hack,alert"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "level") or string.find(chatvars.command, "hack") or string.find(chatvars.command, "alert"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "level" and chatvars.words[3] == "hack" and chatvars.words[4] == "alert" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "disable" then
				server.alertLevelHack = false
				conn:execute("UPDATE server SET alertLevelHack = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will not alert admins when a player's level increases by a large amount.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will not alert admins when a player's level increases by a large amount.")
				end
			else
				server.alertLevelHack = true
				conn:execute("UPDATE server SET alertLevelHack = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot alerts admins when a player's level increases by a large amount.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable airdrop alert"
			help[2] = "By default the bot will inform players when an airdrop occurs near them.  You can disable the message."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,air,drop,alert"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "air"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "airdrop" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "disable" then
				disableTrigger("AirDrop alert")
				server.enableAirdropAlert = 0
				conn:execute("UPDATE server SET enableAirdropAlert = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The bot will say nothing when airdrops occur.[-]")
				else
					irc_chat(chatvars.ircAlias, "The bot will say nothing when airdrops occur.")
				end
			else
				enableTrigger("AirDrop alert")
				server.enableAirdropAlert = 1
				conn:execute("UPDATE server SET enableAirdropAlert = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be alerted to airdrops near their location.[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}block/unblock player {player name}"
			help[2] = "Prevent a player from using IRC.  Other stuff may be blocked in the future."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "block,play,irc"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if not isArchived then
				if chatvars.words[1] == "block" then
					players[id].denyRights = true
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " will be ignored on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[id].name .. " will be ignored on IRC.")
					end
				else
					players[id].denyRights = false
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " can talk to the bot on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[id].name .. " can talk to the bot on IRC.")
					end
				end
			else
				if chatvars.words[1] == "block" then
					playersArchived[id].denyRights = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET denyRights = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " will be ignored on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " will be ignored on IRC.")
					end
				else
					playersArchived[id].denyRights = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET denyRights = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " can talk to the bot on IRC.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable bounty"
			help[2] = "Normally a small bounty is awarded for a player's first pvp kill in pvp rules.  You can disable the automatic bounty.\n"
			help[2] = help[2] .. "Players will still be able to manually place bounties, but those come out of their " .. server.moneyPlural .. "."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,bounty"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bounty")) or string.find(chatvars.command, "pvp")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "bounty" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "disable" then
				server.enableBounty = 0
				conn:execute("UPDATE server SET enableBounty = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The automatic bounty for first kills is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The automatic bounty for first kills is disabled.")
				end
			else
				server.enableBounty = 1
				conn:execute("UPDATE server SET enableBounty = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A small automatic bounty will be awarded for a player's first kill.[-]")
				else
					irc_chat(chatvars.ircAlias, "A small automatic bounty will be awarded for a player's first kill.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	-- This command is no longer needed as the claim scan has been recoded and is much more efficient.
	-- local function cmd_ToggleClaimScan()
		-- if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			-- help = {}
			-- help[1] = " {#}enable/disable claim scan"
			-- help[2] = "The bot reads an individual player's claims when they join and leave the server. Also once per real day it reads all claims (if the server is not busy)."

			-- if botman.registerHelp then
				-- tmp.command = help[1]
				-- tmp.keywords = "able,claim,lcb,key,scan"
				-- tmp.accessLevel = 1
				-- tmp.description = help[2]
				-- tmp.notes = ""
				-- tmp.ingameOnly = 0
				-- registerHelp(tmp)
			-- end

			-- if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				-- irc_chat(chatvars.ircAlias, help[1])

				-- if not shortHelp then
					-- irc_chat(chatvars.ircAlias, help[2])
					-- irc_chat(chatvars.ircAlias, ".")
				-- end

				-- chatvars.helpRead = true
			-- end
		-- end

		-- if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "claim" and chatvars.words[3] == "scan" then
			-- if (chatvars.playername ~= "Server") then
				-- if (chatvars.accessLevel > 1) then
					-- message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					-- botman.faultyChat = false
					-- return true
				-- end
			-- else
				-- if (chatvars.accessLevel > 1) then
					-- irc_chat(chatvars.ircAlias, "This command is restricted.")
					-- botman.faultyChat = false
					-- return true
				-- end
			-- end

			-- if chatvars.words[1] == "disable" then
				-- server.enableTimedClaimScan = 0
				-- conn:execute("UPDATE server SET enableTimedClaimScan = 0")

				-- if (chatvars.playername ~= "Server") then
					-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Claims will not be scanned every minute.[-]")
				-- else
					-- irc_chat(chatvars.ircAlias, "Claims will not be scanned every minute.")
				-- end
			-- else
				-- server.enableTimedClaimScan = 1
				-- conn:execute("UPDATE server SET enableTimedClaimScan = 1")

				-- if (chatvars.playername ~= "Server") then
					-- message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Claims of ingame players (except admins) will be scanned every minute. This can produce a lot of data and may impact server performance.[-]")
				-- else
					-- irc_chat(chatvars.ircAlias, "Claims of ingame players (except admins) will be scanned every minute. This can produce a lot of data and may impact server performance.")
				-- end
			-- end

			-- irc_chat(chatvars.ircAlias, ".")

			-- botman.faultyChat = false
			-- return true
		-- end
	-- end


	local function cmd_ToggleFreezeThawPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}freeze/unfreeze {player name}"
			help[2] = "Bind a player to their current position.  They get teleported back if they move."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "freez,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "freeze" or chatvars.words[1] == "unfreeze" or chatvars.words[1] == "thaw") and chatvars.words[2] ~= nil then
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

			if chatvars.words[1] == "freeze" or chatvars.words[1] == "unfreeze" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "freeze") + 7)
			else
				if chatvars.words[1] == "thaw" then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "thaw") + 5)
				end
			end

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "freeze" then
				if players[id].freeze then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is already frozen.[-]")
					else
						irc_chat(chatvars.ircAlias, players[id].name .. " is already frozen.")
					end

					botman.faultyChat = false
					return true
				end

				if accessLevel(id) < 3 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The staff are cold enough as it is.[-]")
					else
						irc_chat(chatvars.ircAlias, "This command is restricted.")
					end

					botman.faultyChat = false
					return true
				end

				players[id].freeze = true
				players[id].prisonxPosOld = players[id].xPos
				players[id].prisonyPosOld = players[id].yPos
				players[id].prisonzPosOld = players[id].zPos
				message("say [" .. server.chatColour .. "]STOP RIGHT THERE CRIMINAL SCUM![-]")
			else
				if not players[id].freeze then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is not currently frozen.[-]")
					else
						irc_chat(chatvars.ircAlias, players[id].name .. " is not currently frozen.")
					end

					botman.faultyChat = false
					return true
				end

				players[id].freeze = false
				players[id].prisonxPosOld = 0
				players[id].prisonyPosOld = 0
				players[id].prisonzPosOld = 0
				message("say [" .. server.chatColour .. "]Citizen " .. players[id].name .. " you are free to go.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFriendlyPVPResponse()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}ignore/punish friendly pvp"
			help[2] = "By default if a player PVPs where the rules don't permit it, they can get jailed.\n"
			help[2] = help[2] .. "You can tell the bot to ignore friendly kills.  Players must have friended the victim before the PVP occurs."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "pvp"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "ignore" or chatvars.words[1] == "punish") and chatvars.words[2] == "friendly" and chatvars.words[3] == "pvp" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "ignore") then
				server.pvpIgnoreFriendlyKills = true
				if botman.dbConnected then conn:execute("UPDATE server SET pvpIgnoreFriendlyKills = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Friendly PVPs are ignored.[-]")
				else
					irc_chat(chatvars.ircAlias, "Friendly PVPs are ignored.")
				end
			else
				server.pvpIgnoreFriendlyKills = false
				if botman.dbConnected then conn:execute("UPDATE server SET pvpIgnoreFriendlyKills = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Friendly PVP will get the killer jailed.[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}ignore/include player {player name}"
			help[2] = "An ignored player can have uncraftable inventory and do hacker like activity such as teleporting.\n"
			help[2] = help[2] .. "An included player is checked for these things and can be punished or temp banned for them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "play,igno,incl"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "incl") or string.find(chatvars.command, "igno"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "ignore" or chatvars.words[1] == "include") and chatvars.words[2] == "player" and chatvars.words[3] ~= nil then
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

			pname = nil
			pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7)

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if chatvars.words[1] == "ignore" then
				if not isArchived then
					players[id].ignorePlayer = true
					if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is allowed to carry uncraftable items, teleport and other fun stuff.")
					end
				else
					playersArchived[id].ignorePlayer = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET ignorePlayer = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is allowed to carry uncraftable items, teleport and other fun stuff.")
					end
				end
			else
				if not isArchived then
					players[id].ignorePlayer = false
					if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.[-]")
					else
						irc_chat(chatvars.ircAlias,playerName .. " is not allowed to carry uncraftable items, teleport and can be temp banned or made fun of.")
					end
				else
					playersArchived[id].ignorePlayer = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET ignorePlayer = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}include/exclude admins"
			help[2] = "Normally the bot ignores admins when checking inventory and other stuff.  If admins are included, all of the rules that apply to players will also apply to admins.\n"
			help[2] = help[2] .. "This is useful for testing the bot.  You can also use {#}test as player (for 5 minutes)\n"
			help[2] = help[2] .. "This setting is not stored and will revert to excluding admins the next time the bot runs."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "admin,incl,excl,rule"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "clude") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "include" or chatvars.words[1] == "exclude") and chatvars.words[2] == "admins" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "exclude" then
				botman.ignoreAdmins = true

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins can ignore the server rules.[-]")
				else
					irc_chat(chatvars.ircAlias, "Admins can ignore the server rules.")
				end
			else
				botman.ignoreAdmins = false

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins must obey the server rules.  OBEY!  OBEY![-]")
				else
					irc_chat(chatvars.ircAlias, "Admins must obey the server rules.  OBEY!  OBEY!")
				end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TogglePack()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable pack/revive"
			help[2] = "Players can teleport close to where they last died to retrieve their pack.\n"
			help[2] = help[2] .. "You can disable the pack and revive commands.  They are enabled by default."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,pack,revi,spawn"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "pack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and (chatvars.words[2] == "pack" or chatvars.words[2] == "revive") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if (chatvars.words[1] == "enable") then
				server.allowPackTeleport = true
				if botman.dbConnected then conn:execute("UPDATE server SET allowPackTeleport = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players can teleport to their pack when they die.[-]")
				else
					irc_chat(chatvars.ircAlias, "Players can teleport to their pack when they die.")
				end
			else
				server.allowPackTeleport = false
				if botman.dbConnected then conn:execute("UPDATE server SET allowPackTeleport = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The pack and revive commands are disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The pack and revive commands are disabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleRemoveExpiredClaims()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove/leave expired claims"
			help[2] = "By default the bot will not remove expired claims.  It will always ignore admin claims."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "remo,leav,togg,claim,exp"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "remove") or string.find(chatvars.command, "leave") or string.find(chatvars.command, "exp") or string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "remove" or chatvars.words[1] == "leave") and chatvars.words[2] == "expired" and string.find(chatvars.words[3], "claim") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "remove" then
				server.removeExpiredClaims = true
				conn:execute("UPDATE server SET removeExpiredClaims = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expired claims will be removed when players are nearby.[-]")
				else
					irc_chat(chatvars.ircAlias, "Expired claims will be removed when players are nearby.")
				end
			else
				server.removeExpiredClaims = false
				conn:execute("UPDATE server SET removeExpiredClaims = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Expired claims will not be removed.[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reserve/unreserve slot {player name}"
			help[2] = "Give a player the right to take a reserved slot when the server is full.\n"
			help[2] = help[2] .. "Reserved slots are auto assigned for donors and staff."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "slot,reser,play"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "slot") or string.find(chatvars.command, "player") or string.find(chatvars.command, "rese"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reserve" or chatvars.words[1] == "unreserve") and chatvars.words[2] == "slot" then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, " slot ") + 6)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if chatvars.words[1] == "reserve" then
				if not isArchived then
					players[id].reserveSlot = true
					if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can take a reserved slot when the server is full.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can take a reserved slot when the server is full.")
					end
				else
					playersArchived[id].reserveSlot = true
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET reserveSlot = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can take a reserved slot when the server is full.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can take a reserved slot when the server is full.")
					end
				end
			else
				if not isArchived then
					players[id].reserveSlot = false
					if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.")
					end
				else
					playersArchived[id].reserveSlot = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET reserveSlot = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName ..  " can only reserve a slot if they are a donor or staff.[-]")
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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable screamer alert"
			help[2] = "By default the bot will warn players when screamers are approaching.  You can disable that warning."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,scream,scout,alert"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scream"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "screamer" then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			if chatvars.words[1] == "disable" then
				disableTrigger("Zombie Scouts")
				server.enableScreamerAlert = false
				conn:execute("UPDATE server SET enableScreamerAlert = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The screamer alert message is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The screamer alert message is disabled.")
				end
			else
				enableTrigger("Zombie Scouts")
				server.enableScreamerAlert = true
				conn:execute("UPDATE server SET enableScreamerAlert = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players will be warned when screamers are heading towards their location.[-]")
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

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}allow/disallow teleport {player name}"
			help[2] = "Allow or prevent a player from using any teleports.  When disabled, they won't be able to teleport themselves, but they can still be teleported.  Also physical teleports won't work for them."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "allow,tele,play"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "allow" or chatvars.words[1] == "disallow") and chatvars.words[2] == "teleport" and chatvars.words[3] ~= nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, "teleport") + 9)
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if chatvars.words[1] == "disallow" then
				if not isArchived then
					players[id].canTeleport = false
					message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is not allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 0 WHERE steam = " .. id) end
				else
					playersArchived[id].canTeleport = false
					message("say [" .. server.chatColour .. "] " .. playerName ..  " is not allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET canTeleport = 0 WHERE steam = " .. id) end
				end
			else
				if not isArchived then
					players[id].canTeleport = true
					message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 1 WHERE steam = " .. id) end
				else
					playersArchived[id].canTeleport = true
					message("say [" .. server.chatColour .. "] " .. playerName ..  " is allowed to use teleports.[-]")
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET canTeleport = 1 WHERE steam = " .. id) end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWatchPlayer()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}watch {player name}\n"
			help[1] = help[1] .. " {#}watch new players\n"
			help[1] = help[1] .. " {#}stop watching {player name}\n"
			help[1] = help[1] .. " {#}stop watching everyone"
			help[2] = "Flag a player or all current new players for extra attention and logging.  New players are watched by default."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "watc,new,play,every,all,stop"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "watch") or (chatvars.words[1] == "stop" and (chatvars.words[2] == "watching")) then
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

			if (chatvars.words[2] == "new" and chatvars.words[3] == "players") then
				for k,v in pairs(players) do
					if v.newPlayer == true then
						v.watchPlayer = true
						v.watchPlayerTimer = os.time() + server.defaultWatchTimer
						if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = " .. k) end
					end
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players will be watched.[-]")

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "watch") then
				if chatvars.words[2] == "everyone" then -- including staff! :O
					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer) end
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer) end

					for k,v in pairs(igplayers) do
						if players[k].accessLevel > 2 then
							players[k].watchPlayer = true
							players[k].watchPlayerTimer = os.time() + server.defaultWatchTimer
						end
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everyone is being watched right now.  The tinfoil hat does nothing![-]")
					else
						irc_chat(chatvars.ircAlias, "Everyone is being watched right now.  The tinfoil hat does nothing!")
					end

					botman.faultyChat = false
					return true
				else
					pname = string.sub(chatvars.command, string.find(chatvars.command, "watch ") + 6)
					pname = string.trim(pname)
					id = LookupPlayer(pname)
				end

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						playerName = playersArchived[id].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[id].name
					isArchived = false
				end

				if not isArchived then
					players[id].watchPlayer = true
					players[id].watchPlayerTimer = os.time() + server.defaultWatchTimer

					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = " .. id) end
				else
					playersArchived[id].watchPlayer = true
					playersArchived[id].watchPlayerTimer = os.time() + server.defaultWatchTimer

					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + server.defaultWatchTimer .. " WHERE steam = " .. id) end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins will be alerted whenever " .. playerName ..  " enters a base.[-]")
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

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Nobody is being watched right now.[-]")

					botman.faultyChat = false
					return true
				end

				pname = string.sub(chatvars.command, string.find(chatvars.command, "watching ") + 9)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						playerName = playersArchived[id].name
						isArchived = true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				else
					playerName = players[id].name
					isArchived = false
				end

				if not isArchived then
					players[id].watchPlayer = false
					if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id) end
				else
					playersArchived[id].watchPlayer = false
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id) end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playerName ..  " will not be watched.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. playerName ..  " will not be watched.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWaypoints()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable waypoints"
			help[2] = "Donors will be able to create, use and share waypoints.  To enable them for other players, set waypoints public."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "able,wayp,donor"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "enable" or chatvars.words[1] == "disable") and chatvars.words[2] == "waypoints" and chatvars.words[3] == nil then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 0) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
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

			if chatvars.words[1] == "enable" then
				server.allowWaypoints = true

				if botman.dbConnected then conn:execute("UPDATE server SET allowWaypoints = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")
				else
					message("say [" .. server.chatColour .. "]Waypoints are enabled for donors.[-]")
					irc_chat(chatvars.ircAlias, "Waypoints are enabled for donors.")
				end
			else
				server.allowWaypoints = false

				if botman.dbConnected then conn:execute("UPDATE server SET allowWaypoints = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Waypoints are disabled.[-]")
				else
					message("say [" .. server.chatColour .. "]Waypoints are disabled.[-]")
					irc_chat(chatvars.ircAlias, "Waypoints are disabled.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_UnlockAll()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unlockall"
			help[2] = "Unlocks all locked containers etc in your immediate area (the current chunk)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "lock"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "lock"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "unlockall" or (chatvars.words[1] == "unlock" and chatvars.words[2] == "all") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			unlockAll(chatvars.playerid)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Locked containers have been unlocked in the current chunk.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitCrimescene()
		local isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}crimescene {prisoner}"
			help[2] = "Teleport to the coords where a player was when they got arrested."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "pvp,visit,tele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "death") or string.find(chatvars.command, "crime"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "crimescene") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			prisoner = string.sub(chatvars.command, string.find(chatvars.command, "scene ") + 6)
			prisoner = string.trim(prisoner)
			prisonerid = LookupPlayer(prisoner)

			if prisonerid == 0 then
				prisonerid = LookupArchivedPlayer(prisoner)

				if not (prisonerid == 0) then
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
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
				if (players[prisonerid].prisoner) then
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = chatvars.intX
					players[chatvars.playerid].yPosOld = chatvars.intY
					players[chatvars.playerid].zPosOld = chatvars.intZ

					-- then teleport to the prisoners old coords
					cmd = "tele " .. chatvars.playerid .. " " .. players[prisonerid].prisonxPosOld .. " " .. players[prisonerid].prisonyPosOld .. " " .. players[prisonerid].prisonzPosOld
					teleport(cmd, chatvars.playerid)
				else
					-- tp to their return coords if they are set
					if tonumber(players[prisonerid].yPosTimeout) ~= 0 then
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = chatvars.intX
						players[chatvars.playerid].yPosOld = chatvars.intY
						players[chatvars.playerid].zPosOld = chatvars.intZ

						-- then teleport to the prisoners old coords
						cmd = "tele " .. chatvars.playerid .. " " .. players[prisonerid].xPosTimeout .. " " .. players[prisonerid].yPosTimeout .. " " .. players[prisonerid].zPosTimeout
						teleport(cmd, chatvars.playerid)
					end
				end
			else
				if (playersArchived[prisonerid].prisoner) then
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = chatvars.intX
					players[chatvars.playerid].yPosOld = chatvars.intY
					players[chatvars.playerid].zPosOld = chatvars.intZ

					-- then teleport to the prisoners old coords
					cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[prisonerid].prisonxPosOld .. " " .. playersArchived[prisonerid].prisonyPosOld .. " " .. playersArchived[prisonerid].prisonzPosOld
					teleport(cmd, chatvars.playerid)
				else
					-- tp to their return coords if they are set
					if tonumber(players[prisonerid].yPosTimeout) ~= 0 then
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = chatvars.intX
						players[chatvars.playerid].yPosOld = chatvars.intY
						players[chatvars.playerid].zPosOld = chatvars.intZ

						-- then teleport to the prisoners old coords
						cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[prisonerid].xPosTimeout .. " " .. playersArchived[prisonerid].yPosTimeout .. " " .. playersArchived[prisonerid].zPosTimeout
						teleport(cmd, chatvars.playerid)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitPlayerBase()
		local playerName, isArchived

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}playerbase/playerhome {player name}\n"
			help[1] = help[1] .. " {#}playerbase2/playerhome2 {player name}"
			help[2] = "Teleport yourself to the first or second base of a player."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "base,home,tele,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase" or chatvars.words[1] == "playerhome2" or chatvars.words[1] == "playerbase2") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
					botman.faultyChat = false
					return true
				end
			else
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
					isArchived = true
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
				isArchived = false
			end

			if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase") then
				if not isArchived then
					if (players[id].homeX == 0 and players[id].homeZ == 0) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a base yet.[-]")
						botman.faultyChat = false
						return true
					else
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = igplayers[chatvars.playerid].xPos
						players[chatvars.playerid].yPosOld = igplayers[chatvars.playerid].yPos
						players[chatvars.playerid].zPosOld = igplayers[chatvars.playerid].zPos

						cmd = "tele " .. chatvars.playerid .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
						teleport(cmd, chatvars.playerid)
					end
				else
					if (playersArchived[id].homeX == 0 and playersArchived[id].homeZ == 0) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " Has not set a base yet.[-]")
						botman.faultyChat = false
						return true
					else
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = igplayers[chatvars.playerid].xPos
						players[chatvars.playerid].yPosOld = igplayers[chatvars.playerid].yPos
						players[chatvars.playerid].zPosOld = igplayers[chatvars.playerid].zPos

						cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[id].homeX .. " " .. playersArchived[id].homeY .. " " .. playersArchived[id].homeZ
						teleport(cmd, chatvars.playerid)
					end
				end
			else
				if not isArchived then
					if (players[id].home2X == 0 and players[id].home2Z == 0) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a 2nd base yet.[-]")
						botman.faultyChat = false
						return true
					else
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = igplayers[chatvars.playerid].xPos
						players[chatvars.playerid].yPosOld = igplayers[chatvars.playerid].yPos
						players[chatvars.playerid].zPosOld = igplayers[chatvars.playerid].zPos

						cmd = "tele " .. chatvars.playerid .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
						teleport(cmd, chatvars.playerid)
					end
				else
					if (playersArchived[id].home2X == 0 and playersArchived[id].home2Z == 0) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. playerName .. " Has not set a 2nd base yet.[-]")
						botman.faultyChat = false
						return true
					else
						-- first record the current x y z
						players[chatvars.playerid].xPosOld = igplayers[chatvars.playerid].xPos
						players[chatvars.playerid].yPosOld = igplayers[chatvars.playerid].yPos
						players[chatvars.playerid].zPosOld = igplayers[chatvars.playerid].zPos

						cmd = "tele " .. chatvars.playerid .. " " .. playersArchived[id].home2X .. " " .. playersArchived[id].home2Y .. " " .. playersArchived[id].home2Z
						teleport(cmd, chatvars.playerid)
					end

				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WarmPlayer() --tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}warm {player name}"
			help[2] = "Warm a player or yourself if no name given."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "warm,play,buff"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "warm") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "warm") then
			if locations["warm"] then
				botman.faultyChat = false
				return false
			end

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

			if tonumber(server.gameVersionNumber) >= 17 then
				message(string.format("pm %s [%s]This command is for A16 only.", chatvars.playerid, server.chatColour))
				botman.faultyChat = false
				return true
			end

			id = chatvars.playerid

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					id = LookupArchivedPlayer(pname)

					if not (id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
						end

						botman.faultyChat = false
						return true
					end
				end
			end

			if not igplayers[id] then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and is left out in the cold.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and is left out in the cold.")
				end

				botman.faultyChat = false
				return true
			end

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-buffplayer " .. id .. " stewWarming")
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " is warming up.[-]")
			else
				irc_chat(chatvars.ircAlias, players[id].name .. " is warming up.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhitelistAddRemovePlayer()
		local playerName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}whitelist add/remove {player name}"
			help[2] = "Add (or remove) a player to the bot's whitelist. This is not the server's whitelist and it works differently.\n"
			help[2] = help[2] .. "It exempts the player from bot restrictions such as ping kicks and the country blacklist."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "add,remo,white,list,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white") or string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "whitelist" and (chatvars.words[2] == "add" or chatvars.words[2] == "remove") and chatvars.words[3] ~= nil then
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

			pname = nil

			if chatvars.words[2] == "add" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "remove ") + 7)
			end

			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				id = LookupArchivedPlayer(pname)

				if not (id == 0) then
					playerName = playersArchived[id].name
				else
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end
			else
				playerName = players[id].name
			end

			if chatvars.words[2] == "add" then
				whitelist[id] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES (" .. id .. ")") end
				sendCommand("ban remove " .. id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " has been added to the whitelist.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " has been added to the whitelist.")
				end
			else
				whitelist[id] = nil
				if botman.dbConnected then conn:execute("DELETE FROM whitelist WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. playerName .. " is no longer whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, playerName .. " is no longer whitelisted.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WhitelistEveryone()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}whitelist everyone/all"
			help[2] = "You can add everyone except blacklisted players to the bot's whitelist."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "bot,white,list,play"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "whitelist" and (chatvars.words[2] == "everyone" or chatvars.words[2] == "all") then
			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 1) then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]" .. restrictedCommandMessage() .. "[-]")
					botman.faultyChat = false
					return true
				end
			else
				if (chatvars.accessLevel > 1) then
					irc_chat(chatvars.ircAlias, "This command is restricted.")
					botman.faultyChat = false
					return true
				end
			end

			for k,v in pairs(players) do
				if not string.find(server.blacklistCountries, v.country) then
					conn:execute("INSERT INTO whitelist (steam) VALUES (" .. k .. ")")
				end
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everyone except blacklisted players has been whitelisted.[-]")
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
		irc_chat(chatvars.ircAlias, "==== Registering help - admin commands ====")
		dbug("Registering help - admin commands")

		tmp = {}
		tmp.topicDescription = "Admin commands are mainly about doing things to or for players but is also a catchall for commands that don't really fit elsewhere but are for admins."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'admin'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('admin', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "admin" then
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
		irc_chat(chatvars.ircAlias, "Admin Commands:")
		irc_chat(chatvars.ircAlias, "================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "admin")
	end

	result = cmd_AddRemoveAdmin()

	if result then
		if debug then dbug("debug cmd_AddRemoveAdmin triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBadItem()

	if result then
		if debug then dbug("debug cmd_AddRemoveBadItem triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveBlacklistCountry()

	if result then
		if debug then dbug("debug cmd_AddRemoveBlacklistCountry triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveDonor()

	if result then
		if debug then dbug("debug cmd_AddRemoveDonor triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveRestrictedItem()

	if result then
		if debug then dbug("debug cmd_AddRemoveRestrictedItem triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveWhitelistCountry()

	if result then
		if debug then dbug("debug cmd_AddRemoveWhitelistCountry triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ArchivePlayers()

	if result then
		if debug then dbug("debug cmd_ArchivePlayers triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ArrestPlayer()

	if result then
		if debug then dbug("debug cmd_ArrestPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BanUnbanPlayer()

	if result then
		if debug then dbug("debug cmd_BanUnbanPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BlockChatCommandsForPlayer()

	if result then
		if debug then dbug("debug cmd_BlockChatCommandsForPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_BurnPlayer()

	if result then
		if debug then dbug("debug cmd_BurnPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearBlacklist()

	if result then
		if debug then dbug("debug cmd_ClearBlacklist triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ClearWhitelist()

	if result then
		if debug then dbug("debug cmd_ClearWhitelist triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_CoolPlayer()

	if result then
		if debug then dbug("debug cmd_CoolPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_CurePlayer()

	if result then
		if debug then dbug("debug cmd_CurePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_EquipAdmin()

	if result then
		if debug then dbug("debug cmd_EquipAdmin triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ExilePlayer()

	if result then
		if debug then dbug("debug cmd_ExilePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_FreePlayer()

	if result then
		if debug then dbug("debug cmd_FreePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveBackClaims()

	if result then
		if debug then dbug("debug cmd_GiveBackClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveEveryoneItem()

	if result then
		if debug then dbug("debug cmd_GiveEveryoneItem triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GivePlayerItem()

	if result then
		if debug then dbug("debug cmd_GivePlayerItem triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GiveAdminSupplies()

	if result then
		if debug then dbug("debug cmd_GiveAdminSupplies triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_GotoPlayer()

	if result then
		if debug then dbug("debug cmd_GotoPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_HealPlayer()

	if result then
		if debug then dbug("debug cmd_HealPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_HordeMe()

	if result then
		if debug then dbug("debug cmd_HordeMe triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_KickPlayer()

	if result then
		if debug then dbug("debug cmd_KickPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_LeavePlayerClaims()

	if result then
		if debug then dbug("debug cmd_LeavePlayerClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBadItems()

	if result then
		if debug then dbug("debug cmd_ListBadItems triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBasesNearby()

	if result then
		if debug then dbug("debug cmd_ListBasesNearby triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListBlacklist()

	if result then
		if debug then dbug("debug cmd_ListBlacklist triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListClaims()

	if result then
		if debug then dbug("debug cmd_ListClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListOfflinePlayersNearby()

	if result then
		if debug then dbug("debug cmd_ListOfflinePlayersNearby triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListPrisoners()

	if result then
		if debug then dbug("debug cmd_ListPrisoners triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListStaff()

	if result then
		if debug then dbug("debug cmd_ListStaff triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListRestrictedItems()

	if result then
		if debug then dbug("debug cmd_ListRestrictedItems triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListWhitelist()

	if result then
		if debug then dbug("debug cmd_ListWhitelist triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_LoadBotmanINI()

	if result then
		if debug then dbug("debug cmd_LoadBotmanINI triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_MendPlayer()

	if result then
		if debug then dbug("debug cmd_MendPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_MovePlayer()

	if result then
		if debug then dbug("debug cmd_MovePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_NearPlayer()

	if result then
		if debug then dbug("debug cmd_NearPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_PlayerIsNotNew()

	if result then
		if debug then dbug("debug cmd_PlayerIsNotNew triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_PootaterPlayer()

	if result then
		if debug then dbug("debug cmd_PootaterPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReadClaims()

	if result then
		if debug then dbug("debug cmd_ReadClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReleasePlayer()

	if result then
		if debug then dbug("debug cmd_ReleasePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReleasePlayerHere()

	if result then
		if debug then dbug("debug cmd_ReleasePlayerHere triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReloadAdmins()

	if result then
		if debug then dbug("debug cmd_ReloadAdmins triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemovePlayerClaims()

	if result then
		if debug then dbug("debug cmd_RemovePlayerClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPlayer()

	if result then
		if debug then dbug("debug cmd_ResetPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPlayerTimers()

	if result then
		if debug then dbug("debug cmd_ResetPlayerTimers triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetStackSizes()

	if result then
		if debug then dbug("debug cmd_ResetStackSizes triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_RestoreAdmin()

	if result then
		if debug then dbug("debug cmd_RestoreAdmin triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ReturnPlayer()

	if result then
		if debug then dbug("debug cmd_ReturnPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendPlayerHome()

	if result then
		if debug then dbug("debug cmd_SendPlayerHome triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SendPlayerToPlayer()

	if result then
		if debug then dbug("debug cmd_SendPlayerToPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetDropMiningWarningThreshold()

	if result then
		if debug then dbug("debug cmd_SetDropMiningWarningThreshold triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetCommandCooldown()

	if result then
		if debug then dbug("debug cmd_SetCommandCooldown triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetFeralHordeNight()

	if result then
		if debug then dbug("debug cmd_SetFeralHordeNight triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetFeralRebootDelay()

	if result then
		if debug then dbug("debug cmd_SetFeralRebootDelay triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxTrackingDays()

	if result then
		if debug then dbug("debug cmd_SetMaxTrackingDays triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReservedSlotTimelimit()

	if result then
		if debug then dbug("debug cmd_SetReservedSlotTimelimit triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetReturnCooldown()

	if result then
		if debug then dbug("debug cmd_SetReturnCooldown triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetViewArrestReason()

	if result then
		if debug then dbug("debug cmd_SetViewArrestReason triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetWatchPlayerTimer()

	if result then
		if debug then dbug("debug cmd_SetWatchPlayerTimer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ShitPlayer()

	if result then
		if debug then dbug("debug cmd_ShitPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TestAsPlayer()

	if result then
		if debug then dbug("debug cmd_TestAsPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TimeoutPlayer()

	if result then
		if debug then dbug("debug cmd_TimeoutPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleLevelHackAlert()

	if result then
		if debug then dbug("debug cmd_ToggleLevelHackAlert triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleAirdropAlert()

	if result then
		if debug then dbug("debug cmd_ToggleAirdropAlert triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBounties()

	if result then
		if debug then dbug("debug cmd_ToggleBounties triggered") end
		return result
	end

	-- if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	-- result = cmd_ToggleClaimScan()

	-- if result then
		-- if debug then dbug("debug cmd_ToggleClaimScan triggered") end
		-- return result
	-- end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFriendlyPVPResponse()

	if result then
		if debug then dbug("debug cmd_ToggleFriendlyPVPResponse triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleBlockPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleBlockPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleFreezeThawPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleFreezeThawPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIncludeExcludeAdmins()

	if result then
		if debug then dbug("debug cmd_ToggleIncludeExcludeAdmins triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleIgnorePlayer()

	if result then
		if debug then dbug("debug cmd_ToggleIgnorePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_TogglePack()

	if result then
		if debug then dbug("debug cmd_TogglePack triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleRemoveExpiredClaims()

	if result then
		if debug then dbug("debug cmd_ToggleRemoveExpiredClaims triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleReservedSlotPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleReservedSlotPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleScreamerAlert()

	if result then
		if debug then dbug("debug cmd_ToggleScreamerAlert triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleTeleportPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleTeleportPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWatchPlayer()

	if result then
		if debug then dbug("debug cmd_ToggleWatchPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleWaypoints()

	if result then
		if debug then dbug("debug cmd_ToggleWaypoints triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_UnlockAll()

	if result then
		if debug then dbug("debug cmd_UnlockAll triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitCrimescene()

	if result then
		if debug then dbug("debug cmd_VisitCrimescene triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_VisitPlayerBase()

	if result then
		if debug then dbug("debug cmd_VisitPlayerBase triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_WarmPlayer()

	if result then
		if debug then dbug("debug cmd_WarmPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhitelistAddRemovePlayer()

	if result then
		if debug then dbug("debug cmd_WhitelistAddRemovePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_WhitelistEveryone()

	if result then
		if debug then dbug("debug cmd_WhitelistEveryone triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Admin commands help registered ****")
		dbug("Admin commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug admin end") end

	-- can't touch dis
	if true then
		return result
	end
end
