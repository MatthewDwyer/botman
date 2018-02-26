--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]


--[[
add /claims <distance> it will count all claims (using llp) within range.
add /claim owners <distance> will list all the players with claims down in range
--]]

local debug, tmp, str, counter, r, id, pname, result
local shortHelp = false
local skipHelp = false

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

if botman.debugAll then
	debug = true
end

function gmsg_admin()
	calledFunction = "gmsg_admin"
	result = false

	tmp = {}

-- ################## Admin command functions ##################

	local function cmd_AddRemoveAdmin()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "remove") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "admin add {player or steam or game ID} level {0-2}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "admin remove {player or steam or game ID}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give a player admin status and a level, or take it away.")
					irc_chat(chatvars.ircAlias, "Server owners are level 0, admins are level 1 and moderators level 2.  The bot does not currently recognise other admin levels.")
					irc_chat(chatvars.ircAlias, ".")
					irc_chat(chatvars.ircAlias, "Or remove an admin so they become a regular player.")
					irc_chat(chatvars.ircAlias, "This does not stop them using god mode etc if they are ingame and already have dm enabled.  They must leave the server or disable dm themselves.")
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
			id = LookupPlayer(pname)
			number = -1

			if id == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
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

					players[id].newPlayer = false
					players[id].silentBob = false
					players[id].walkies = false
					players[id].exiled = 2
					players[id].canTeleport = true
					players[id].botHelp = true

					if tonumber(players[id].accessLevel) > tonumber(number) then
						players[id].accessLevel = number
					end

					message("say [" .. server.chatColour .. "]" .. players[id].name .. " has been given admin powers[-]")
					send("admin add " .. id .. " " .. number)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end
			else
				-- remove the steamid from the admins table
				owners[players[id].steam] = nil
				admins[players[id].steam] = nil
				mods[players[id].steam] = nil
				players[id].accessLevel = 90

				message("say [" .. server.chatColour .. "]" .. players[id].name .. "'s admin powers have been revoked[-]")
				send("admin remove " .. id)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBadItem()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add/remove bad item {item}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Add or remove an item to/from the list of bad items.  The default action is to timeout the player.")
					irc_chat(chatvars.ircAlias, "See also " .. server.commandPrefix .. "ignore player {name} and " .. server.commandPrefix .. "include player {name}")
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

			bad = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "bad item") + 9)

			if chatvars.words[1] == "add" then
				badItems[bad] = {}
				if botman.dbConnected then conn:execute("INSERT INTO badItems SET item = '" .. bad .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. bad .. " to the list of bad items.[-]")
				else
					irc_chat(chatvars.ircAlias, "You added " .. bad .. " to the list of bad items.")
				end
			else
				bad = string.sub(chatvars.oldLine, string.find(chatvars.oldLine, "bad item") + 9)

				badItems[bad] = nil
				if botman.dbConnected then conn:execute("DELETE FROM badItems WHERE item = '" .. bad .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of bad items.[-]")
				else
					irc_chat(chatvars.ircAlias, "You removed " .. bad .. " from the list of bad items.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveBlacklistCountry()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add blacklist country {US}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove blacklist country {US}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Add or remove a country to/from the blacklist. Note: Use 2 letter country codes only.")
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


	local function cmd_AddRemoveDonor()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "donor"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add donor {player name} level {0 to 7} expires {number} week or month or year")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove donor {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give a player donor status.  This doesn't have to involve money.  Donors get a few perks above other players but no items or " .. server.moneyPlural .. ".")
					irc_chat(chatvars.ircAlias, "Level and expiry are optional.  The default is level 1 and expiry 10 years.")
					irc_chat(chatvars.ircAlias, "You can also temporarily raise everyone to donor level with " .. server.commandPrefix .. "override access.")
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

			tmp.id = LookupPlayer(tmp.pname)

			-- no player found
			if tmp.id == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
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

				tmp.sql = "UPDATE players SET donor = 1"
				tmp.sql = tmp.sql .. ", donorExpiry = " .. tmp.expiry .. ", donorLevel = " .. tmp.level .. ", maxWaypoints = " .. server.maxWaypointsDonors

				-- set the donor flag to true
				players[tmp.id].donor = true
				players[tmp.id].donorLevel = tmp.level
				players[tmp.id].donorExpiry = tmp.expiry
				players[tmp.id].maxWaypoints = server.maxWaypointsDonors
				if botman.dbConnected then conn:execute(tmp.sql .. " WHERE steam = " .. tmp.id) end

				-- also add them to the bot's whitelist
				whitelist[tmp.id] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES (" .. tmp.id .. ")") end

				-- remove any ban against them
				send("ban remove " .. tmp.id)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				-- create or update the donor record on the shared database
				if server.serverGroup ~= "" then
					connBots:execute("INSERT INTO donors (donor, donorLevel, donorExpiry, steam, botID, serverGroup) VALUES (1, " .. tmp.level .. ", " .. tmp.expiry .. ", " .. tmp.id .. "," .. server.botID .. ",'" .. escape(server.serverGroup) .. "')")
					connBots:execute("UPDATE donors SET donor = 1, donorLevel = " .. tmp.level .. ", donorExpiry = " .. tmp.expiry .. " WHERE steam = " .. tmp.id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
				end

				message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has donated! Thanks =D[-]")
			else
				-- remove a donor

				-- set the donor flag to false
				players[tmp.id].donor = false
				players[tmp.id].donorLevel = 0
				players[tmp.id].donorExpiry = os.time() - 1
				players[tmp.id].maxWaypoints = server.maxWaypoints

				if botman.dbConnected then conn:execute("UPDATE players SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. tmp.id) end

				-- to prevent the player having too many waypoints, we delete them.
				if botman.dbConnected then conn:execute("DELETE FROM waypoints WHERE steam = " .. tmp.id) end

				-- reload the player's waypoints
				loadWaypoints(tmp.id)

				if server.serverGroup ~= "" then
					connBots:execute("UPDATE donors SET donor = 0, donorLevel = 0, donorExpiry = " .. os.time() - 1 .. " WHERE steam = " .. tmp.id .. " AND serverGroup = '" .. escape(server.serverGroup) .. "'")
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " no longer has donor status.[-]")
				else
					irc_chat(chatvars.ircAlias, players[tmp.id].name .. " no longer has donor status.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveRestrictedItem()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or (string.find(chatvars.command, "remove")) or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add restricted item {item name} qty {count} action {action} access {level}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove restricted item {item name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Add an item to the list of restricted items.")
					irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile  and watch")
					irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "add restricted item tnt qty 5 action timeout access 90")
					irc_chat(chatvars.ircAlias, "Players with access > 90 will be sent to timeout for more than 5 tnt.")
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
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item, qty and access are required.[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout[-]")
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Valid actions are timeout, ban, exile. Bans last 1 day.[-]")
					else
						irc_chat(chatvars.ircAlias, "Item, qty and access are required.")
						irc_chat(chatvars.ircAlias, "eg. " .. server.commandPrefix .. "add restricted item mineCandyTin qty 20 access 99 action timeout")
						irc_chat(chatvars.ircAlias, "Valid actions are timeout, ban, exile. Bans last 1 day.")
					end
				else
					if botman.dbConnected then
						conn:execute("INSERT INTO restrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
						conn:execute("INSERT INTO memRestrictedItems (item, qty, accessLevel, action) VALUES ('" .. escape(item) .. "'," .. qty .. "," .. access .. ",'" .. action .. "') ON DUPLICATE KEY UPDATE item = '" .. escape(item) .. "', qty = " .. qty .. ", accessLevel = " .. access .. ", action = '" .. action .. "'")
					end

					restrictedItems[item] = {}
					restrictedItems[item].qty = tonumber(qty)
					restrictedItems[item].accessLevel = tonumber(access)
					restrictedItems[item].action = action

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.[-]")
					else
						irc_chat(chatvars.ircAlias, "You added " .. item .. " quantity " .. qty .. " with minimum access level " .. access .. " and action " .. action .. " to restricted items.")
					end
				end
			else
				-- remove restricted item
				bad = string.sub(chatvars.command, string.find(chatvars.command, "restricted item") + 16)

				if botman.dbConnected then
					conn:execute("DELETE FROM restrictedItems WHERE item = '" .. bad .. "'")
					conn:execute("DELETE FROM memRestrictedItems WHERE item = '" .. bad .. "'")
				end

				restrictedItems[bad] = nil
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed " .. bad .. " from the list of restricted items[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_AddRemoveWhitelistCountry()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "add whitelist country {US}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove whitelist country {US}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Add or remove a country to/from the whitelist. Note: Use 2 letter country codes.")
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

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ArrestPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "arrest") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "jail"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "arrest {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "arrest {player name} reason {why arrested}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Send a player to prison.  If the location prison does not exist they are temp-banned instead.")
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
			prisonerid = LookupPlayer(prisoner)

			if prisonerid == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. prisoner .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found called " .. prisoner)
				end

				botman.faultyChat = false
				return true
			end

			prisoner = players[prisonerid].name

			if (players[prisonerid]) then
				if (players[prisonerid].timeout == true) then
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


	local function cmd_BanUnbanPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ban") or string.find(chatvars.command, "black") or string.find(chatvars.command, "gbl") or string.find(chatvars.command, "glob"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "ban {player name} (ban for 10 years with the reason 'banned')")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "ban {player name} reason {reason for ban} (ban for 10 years with the reason you provided)")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "ban {player name} time {number} hour or day or month or year reason {reason for ban}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "unban {player name}")
				irc_chat(chatvars.ircAlias, ".")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "gblban {player name} reason {reason for ban}")
				irc_chat(chatvars.ircAlias, "Global bans are vetted before they become active.  If the player is later caught hacking by a bot and they have pending global bans, a new active global ban is added automatically.")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Ban a player from the server.  You can optionally give a reason and a duration. The default is a 10 year ban with the reason 'banned'.")
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

			if chatvars.words[1] == "ban" then
				reason = "banned"
				duration = "10 years"

				if not string.find(chatvars.command, "reason") and not string.find(chatvars.command, "time") then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4)
				end

				if string.find(chatvars.command, "reason") then
					pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, "reason") - 2)

					if string.find(chatvars.command, " time") then
						pname = string.sub(chatvars.command, string.find(chatvars.command, "ban ") + 4, string.find(chatvars.command, "time") - 2)
					end
				end

				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if chatvars.playerid ~= Smegz0r then
					if id == 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. pname .. ".[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. pname)
						end

						botman.faultyChat = false
						return true
					else
						-- don't ban if player is an admin :O
						if accessLevel(id) < 3 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You what?  You want to global ban one of your own admins?   [DENIED][-]")
							else
								irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of your own admins?   [DENIED]")
							end

							botman.faultyChat = false
							return true
						end
					end
				end

				if string.find(chatvars.command, "reason") then
					reason = string.sub(chatvars.command, string.find(chatvars.command, "reason ") + 7)
				end

				if string.find(chatvars.command, "time") then
					if string.find(chatvars.command, "reason") then
						duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5, string.find(chatvars.command, "reason") - 2)
					else
						duration = string.sub(chatvars.command, string.find(chatvars.command, "time ") + 5)
					end
				end
			end

			if chatvars.words[1] == "unban" then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "unban ") + 6)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
				end

				send("ban remove " .. id)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been unbanned.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " has been unbanned.")
				end
			end


			if chatvars.words[1] ~= "gblban" then
				banPlayer(id, duration, reason, chatvars.playerid)
			else
				if id ~= nil then
					-- don't ban if player is an admin :O
					if accessLevel(id) < 3 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You what?  You want to global ban one of your own admins?   [DENIED][-]")
						else
							irc_chat(chatvars.ircAlias, "You what?  You want to global ban one of your own admins?   [DENIED]")
						end

						botman.faultyChat = false
						return true
					end

					cursor,errorString = connBots:execute("SELECT * FROM bans where steam = " .. id .. " AND botID = " .. server.botID)
				else
					-- pname must be a steam id
					id = pname
					cursor,errorString = connBots:execute("SELECT * FROM bans where steam = " .. pname .. " AND botID = " .. server.botID)
				end

				rows = cursor:numrows()

				if rows == 0 then
					connBots:execute("INSERT INTO bans (steam, reason, GBLBan, GBLBanReason, botID) VALUES (" .. id .. ",'" .. escape(reason) .. "',1,'" .. escape(reason) .. "'," .. server.botID .. ")")
					banPlayer(id, duration, reason, chatvars.playerid)
				else
					connBots:execute("UPDATE bans set GBLBan = 1, GBLBanReason = '" .. escape(reason) .. "' WHERE steam = " .. id .. " AND botID = " .. server.botID)
				end

				if (chatvars.playername ~= "Server") then
					if players[id] then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been submitted to the global ban list for approval.[-]")
					else
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " has been submitted to the global ban list for approval.[-]")
					end

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Until approved, it will only raise an alert when the player joins another server.[-]")
				else
					if players[id] then
						irc_chat(chatvars.ircAlias, players[id].name .. " has been submitted to the global ban list for approval.")
					else
						irc_chat(chatvars.ircAlias, pname .. " has been submitted to the global ban list for approval.")
					end

					irc_chat(chatvars.ircAlias, "Until approved, it will only raise an alert when the player joins another server.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BlockChatCommandsForPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "block") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "block {name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "unblock {name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Block/Unblock a player from using any bot commands or command the bot from IRC.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "block" or chatvars.words[1] == "unblock") and chatvars.words[2] ~= nil then
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

			pname = string.sub(chatvars.command, string.find(chatvars.command, chatvars.words[1], nil, true) + string.len(chatvars.words[1]))
			pname = string.trim(pname)
			id = LookupPlayer(pname)

			if id == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "block") then
				players[id].block = true
				if botman.dbConnected then conn:execute("UPDATE players SET block=1 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. players[id].name .. " is blocked from talking to the bot.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " is blocked from talking to the bot.")
				end
			else
				players[id].block = false
				if botman.dbConnected then conn:execute("UPDATE players SET block=0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]Player " .. players[id].name .. " can talk to the bot.", chatvars.playerid, server.chatColour))
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " can talk to the bot.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_BurnPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "burn") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "burn {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Set a player on fire.  It usually kills them.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "burn" and chatvars.words[2] ~= nil) then
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

			if (chatvars.words[2] ~= nil) then
				pname = chatvars.words[2]
				id = LookupPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
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

			send("buffplayer " .. id .. " burning") -- yeah baby!

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You set " .. players[id].name .. " on fire![-]")

				if accessLevel(id) < 3 then
					message("pm " .. id .. " [" .. server.alertColour .. "]" .. players[chatvars.playerid].name .. " set you on fire![-]")
				end
			else
				irc_chat(chatvars.ircAlias, "You set " .. players[id].name .. " on fire!")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ClearBlacklist()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "clear country blacklist")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Remove all countries from the blacklist. (yay?)")
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


	local function cmd_ClearWhitelist()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "clear country whitelist")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Remove all countries from the whitelist.")
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


	local function cmd_CoolPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cool") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "cool {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Cool a player or yourself if no name given.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "cool") then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now.  They aren't cool enough.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now. They aren't cool enough.")
				end

				botman.faultyChat = false
				return true
			end

			send("buffplayer " .. id .. " redTeaCooling")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
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


	local function cmd_CurePlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "cure") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "cure {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Cure a player or yourself if no name given.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "cure") then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now. Next patient please![-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now. Next patient please!")
				end

				botman.faultyChat = false
				return true
			end

			send("buffplayer " .. id .. " cured")
			send("debuffplayer " .. id .. " dysentery")
			send("debuffplayer " .. id .. " dysentery2")
			send("debuffplayer " .. id .. " foodPoisoning")
			send("debuffplayer " .. id .. " infection")
			send("debuffplayer " .. id .. " infection1")
			send("debuffplayer " .. id .. " infection2")
			send("debuffplayer " .. id .. " infection3")
			send("debuffplayer " .. id .. " infection4")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 9
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "equip") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "equip admin")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Spawn various items on you.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later.")
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


			-- auger
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " auger /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " auger 1 600"
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "auger")

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- chainsaw
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " chainsaw /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " chainsaw 1 600"
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "chainsaw")

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- nailgun
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " nailgun /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " nailgun 1 600"
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "nailgun")

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- mining helment
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " miningHelmet /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " miningHelmet 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "miningHelmet")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "miningHelmet")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- militaryVest
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " militaryVest /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " militaryVest 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "militaryVest")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "militaryVest")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- militaryLegArmor
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " militaryLegArmor /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " militaryLegArmor 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "militaryLegArmor")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "militaryLegArmor")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- militaryBoots
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " militaryBoots /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " militaryBoots 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "militaryBoots")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "militaryBoots")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- militaryBoots
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " militaryGloves /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " militaryGloves 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "militaryGloves")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "militaryGloves")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- leatherDuster
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " leatherDuster /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " leatherDuster 1 600"
			end

			tmp.found, tmp.quality = getEquipment(tmp.equipment, "leatherDuster")

			if not tmp.found then
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "leatherDuster")
			end

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- gunMP5
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " gunMP5 /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " gunMP5 1 600"
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gunMP5")

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- gunPumpShotgun
			if server.stompy then
				tmp.cmd = "bc-give " .. chatvars.playerid .. " gunPumpShotgun /c=1 /q=600 /silent"
			else
				tmp.cmd = "give " .. chatvars.playerid .. " gunPumpShotgun 1 600"
			end

			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gunPumpShotgun")

			if not tmp.found then
				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quality < 100 then
					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- redTea
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "redTea")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " redTea 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " redTea " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- gasCan
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gasCan")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=400 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " gasCan 400"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 400 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=" .. 400 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " gasCan " .. 400 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- meatStew
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "meatStew")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=20 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " meatStew 20"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 20 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=" .. 20 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " meatStew " .. 20 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- firstAidKit
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "firstAidKit")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- antibiotics
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "antibiotics")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " antibiotics 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " antibiotics " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- 9mmBullet
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "9mmBullet")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " 9mmBullet /c=500 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " 9mmBullet 500"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 500 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " 9mmBullet /c=" .. 500 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " 9mmBullet " .. 500 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			-- shotgunShell
			tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "shotgunShell")

			if not tmp.found then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=500 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell 500"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				if tmp.quantity < 500 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=" .. 500 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell " .. 500 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "exile")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "exile {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Bannish a player to a special location called " .. server.commandPrefix .. "exile which must exist first.")
					irc_chat(chatvars.ircAlias, "While exiled, the player will not be able to command the bot.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id ~= 0 then
				-- flag the player as exiled
				players[id].exiled = 1
				players[id].silentBob = true
				players[id].canTeleport = false

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[id].name .. " has been exiled.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " has been exiled.")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FreePlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "exile") or string.find(chatvars.command, "free"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "free {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Release the player from exile, however it does not return them.  They can type " .. server.commandPrefix .. "return or you can return them.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id ~= 0 then
				-- flag the player as no longer exiled
				players[id].exiled = 2
				players[id].silentBob = false
				players[id].canTeleport = true
				message("say [" .. server.chatColour .. "]" .. players[id].name .. " has been released from exile! :D[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET exiled = 2, silentBob = 0, canTeleport = 1 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveAdminSupplies()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "supp") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "inv"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "supplies")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Spawn various items on you like equip admin does but no armour or guns.  The bot checks your inventory and will top you up instead of doubling up if you repeat this command later.")
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

			if not string.find(tmp.inventory, "redTea") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " redTea 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "redTea")

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " redTea /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " redTea " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "gasCan") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=800 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " gasCan 800"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "gasCan")

				if tonumber(tmp.quantity) < 800 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " gasCan /c=" .. 800 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " gasCan " .. 800 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "meatStew") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=20 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " meatStew 20"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "meatStew")

				if tonumber(tmp.quantity) < 20 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " meatStew /c=" .. 20 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " meatStew " .. 20 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "firstAidKit") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "firstAidKit")

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " firstAidKit /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " firstAidKit " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "antibiotics") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=10 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " antibiotics 10"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "antibiotics")

				if tonumber(tmp.quantity) < 10 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " antibiotics /c=" .. 10 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " antibiotics " .. 10 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end


			if not string.find(tmp.inventory, "shotgunShell") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=500 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell 500"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "shotgunShell")

				if tonumber(tmp.quantity) < 500 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " shotgunShell /c=" .. 500 - tonumber(tmp.quantity) .. " /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " shotgunShell " .. 500 - tonumber(tmp.quantity)
					end

					if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
					tmp.gaveStuff = true
				end
			end

			if not string.find(tmp.inventory .. tmp.equipment, "miningHelmet") then
				if server.stompy then
					tmp.cmd = "bc-give " .. chatvars.playerid .. " miningHelmet /c=1 /q=600 /silent"
				else
					tmp.cmd = "give " .. chatvars.playerid .. " miningHelmet 1 600"
				end

				if botman.dbConnected then conn:execute("INSERT into gimmeQueue (command, steam) VALUES ('" .. escape(tmp.cmd) .. "', " .. chatvars.playerid .. ")") end
				tmp.gaveStuff = true
			else
				tmp.found, tmp.quality = getEquipment(tmp.equipment, "miningHelmet")

				if not tmp.found then
					tmp.found, tmp.quantity, tmp.quality = getInventory(tmp.inventory, "miningHelmet")
				end

				if tmp.found and tmp.quality < 300 then
					if server.stompy then
						tmp.cmd = "bc-give " .. chatvars.playerid .. " miningHelmet /c=1 /q=600 /silent"
					else
						tmp.cmd = "give " .. chatvars.playerid .. " miningHelmet 1 600"
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give") or string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "give claim/key/lcb")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "The bot can despawn player placed claims in reset zones.  This command is for them to request them back from the bot.")
					irc_chat(chatvars.ircAlias, "It will only return the number that it took away.  If it isn't holding any, it won't give any back.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "give" and (string.find(chatvars.words[2], "claim") or string.find(chatvars.words[2], "key") or string.find(chatvars.words[2], "lcb")) then
			if players[chatvars.playerid].removedClaims > 0 then
				if server.stompy then
					send("bc-give " .. chatvars.playerid .. " keystoneBlock /c=" .. players[chatvars.playerid].removedClaims)
				else
					send("give " .. chatvars.playerid .. " keystoneBlock " .. players[chatvars.playerid].removedClaims)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I was holding " .. players[chatvars.playerid].removedClaims .. " keystones for you and have dropped them at your feet.  Press e to collect them now.[-]")
				players[chatvars.playerid].removedClaims = 0
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I have no keystones to give you at this time.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_GiveEveryoneItem()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, string.format(" %sgive everyone {item} {amount} {quality}", server.commandPrefix))

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give everyone that is playing on the server right now an amount of an item. The default is to give 1 item.")
					irc_chat(chatvars.ircAlias, "If quality is not given, it will have a random quality for each player.")
					irc_chat(chatvars.ircAlias, "Anyone not currently playing will not receive the item.")
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
						send("bc-give " .. k .. " " .. chatvars.wordsOld[3] .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality)
					else
						send("give " .. v.id .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity .. " " .. tmp.quality)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", k, server.chatColour, chatvars.wordsOld[3]))
					end
				else
					if server.stompy then
						send("bc-give " .. k .. " " .. chatvars.wordsOld[3] .. " /c=" .. tmp.quantity)
					else
						send("give " .. v.id .. " " .. chatvars.wordsOld[3] .. " " .. tmp.quantity)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", k, server.chatColour, chatvars.wordsOld[3]))
					end
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "give"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "give player {joe} item {item} {amount} {quality}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "give player {joe} item {item} {amount} {quality} message {say something here}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give a specific player amount of an item. The default is to give 1 item.")
					irc_chat(chatvars.ircAlias, "The player does not need to be on the server.  They will receive the item and optional message when they next join.")
					irc_chat(chatvars.ircAlias, "You can give more items but only 1 item type per command.  Items are given in the same order so you could include a message with the first item and they will read that first.")
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

				dbug("tmp.message " .. tmp.message)
			end

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "player ") + 7, string.find(chatvars.command, " item ") - 1)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)

			if tmp.id == nil then
				if (chatvars.playername ~= "Server") then
					message(string.format("pm %s [%s]No player found called %s[-]", chatvars.playerid, server.chatColour, tmp.pname))
					botman.faultyChat = false
					return true
				else
					irc_chat(chatvars.ircAlias, string.format("No player found called %s", tmp.pname))
					botman.faultyChat = false
					return true
				end
			end

			if igplayers[tmp.id] then
				if tmp.quality then
					if server.stompy then
					dbug("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality)
						send("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity .. " /q=" .. tmp.quality)
					else
						send("give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity .. " " .. tmp.quality)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", tmp.id, server.chatColour, tmp.item))
					end
				else
					if server.stompy then
					dbug("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity)
						send("bc-give " .. tmp.id .. " " .. tmp.item .. " /c=" .. tmp.quantity)
					else
						send("give " .. tmp.id .. " " .. tmp.item .. " " .. tmp.quantity)
						message(string.format("pm %s [%s]>FREE< STUFF!  Press e to pick up some %s now. =D[-]", tmp.id, server.chatColour, tmp.item))
					end
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "goto {player or steam or game ID}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport to the current position of a player.")
					irc_chat(chatvars.ircAlias, "This works with offline players too.")
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

			if (players[chatvars.playerid].timeout == true) then
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			-- then teleport to the player
			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(players[id].xPos) + 1 .. " " .. math.ceil(players[id].yPos) .. " " .. math.floor(players[id].zPos)
			teleport(cmd, chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_HealPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "heal") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "heal {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Apply big firstaid buff to a player or yourself if no name given.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "heal") then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now so get your filthy ape hands off them![-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now so get your filthy ape hands off them!")
				end

				botman.faultyChat = false
				return true
			end

			send("buffplayer " .. id .. " firstAid")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
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


	local function cmd_HordeMe()
		if (chatvars.words[1] == "hordeme") or (string.find(chatvars.command, "this is sparta")) then
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "kick"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "kick {Player name|Steam ID|Game ID} reason {optional reason}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Is Joe annoying you?  Kick his ass right out of the server! >:D")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "kick" and chatvars.words[2] ~= nil) then
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
				id = LookupPlayer(pname)

				reason = string.sub(chatvars.command, string.find(chatvars.command, "reason ") + 7)
			else
				pname = string.sub(chatvars.command, string.find(chatvars.command, "kick ") + 5)
				id = LookupPlayer(pname)
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " is not on the server right now.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " is not on the server right now.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "leave claims {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Stop the bot automatically removing a player's claims.  They will still be removed if they are in a location that doesn't allow player claims.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id ~= 0 then
				-- this player's claims will not be removed unless in a reset zone and not staff
				players[id].removeClaims = false
				if botman.dbConnected then conn:execute("UPDATE keystones SET remove = 0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. "'s claims will not be removed unless found in reset zones (if not staff).[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. "'s claims will not be removed unless found in reset zones (if not staff)")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 0 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBadItems()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "bad"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "bad items")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List the items that are not allowed in player inventories and what action is taken.")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I scan for these items in inventory:[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Item        Action[-]")
			else
				irc_chat(chatvars.ircAlias, "I scan for these items in inventory:")
				irc_chat(chatvars.ircAlias, "Item        Action")
			end

			for k, v in pairs(badItems) do
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. k .. "   " .. v.action  .. "[-]")
				else
					irc_chat(chatvars.ircAlias, k .. "   " .. v.action)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBasesNearby()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "base") or string.find(chatvars.command, "home") or string.find(chatvars.command, "admin"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "bases (or homes)")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "bases range {number}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "bases near {player name} range {number}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "See what player bases are nearby.  You can use it on yourself or on a player.")
					irc_chat(chatvars.ircAlias, "Range and player are optional.  The default range is 200 metres.")
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

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
							alone = false
						end
					end

					if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
						dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.home2X, v.home2Z)

						if dist < tonumber(chatvars.number) then
							if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of you are:[-]") end

							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
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

				name1 = string.trim(name1)
				id = LookupPlayer(name1)

				if (id ~= 0) then
					for k, v in pairs(players) do
						if (v.homeX) and (v.homeX ~= 0 and v.homeZ ~= 0) then
							dist = distancexz(igplayers[id].xPos, igplayers[id].zPos, v.homeX, v.homeZ)

							if dist < tonumber(chatvars.number) then
								if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. players[id].name .. " are:[-]") end

								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
								alone = false
							end
						end

						if (v.home2X) and (v.home2X ~= 0 and v.home2Z ~= 0) then
							dist = distancexz(igplayers[id].xPos, igplayers[id].zPos, v.home2X, v.home2Z)

							if dist < tonumber(chatvars.number) then
								if (alone == true) then message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]player bases within " .. chatvars.number .. " meters of " .. players[id].name .. " are:[-]") end

								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%-8.2d", dist) .. " meters[-]")
								alone = false
							end
						end
					end

					if (alone == true) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There are none within " .. chatvars.number .. " meters of " .. players[id].name .. "[-]")
					end
				else
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. name1 .. "[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListBlacklist()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "blacklist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "list blacklist")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List the countries that are not allowed to play on the server.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "claims {range} (range is optional and defaults to 50)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List all of the claims within range with who owns them")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "offline") or string.find(chatvars.command, "player") or string.find(chatvars.command, "near"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "offline players nearby")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "offline players nearby range {number}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List all offline players near your position. The default range is 200 metres.")
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

			for k, v in pairs(players) do
				if igplayers[k] == nil and v.xPos ~= nil then
					dist = distancexz(igplayers[chatvars.playerid].xPos, igplayers[chatvars.playerid].zPos, v.xPos, v.zPos)
					dist = math.abs(dist)

					if tonumber(dist) <= tonumber(chatvars.number) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. v.name .. " distance: " .. string.format("%d", dist) .. "[-]")
						alone = false
					end
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "prison") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "prisoners")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List all the players who are prisoners.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item") or string.find(chatvars.command, "rest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "restricted items")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List the items that new players are not allowed to have in inventory and what action is taken.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "staff"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "list staff (or admins)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Lists the server staff and shows who if any are playing.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "list" and (chatvars.words[2] == "staff" or chatvars.words[2] == "admins") or (chatvars.words[1] == "admins" or chatvars.words[1] == "staff") and chatvars.words[3] == nil) then
			listStaff(chatvars.playerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListWhitelist()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "whitelist"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "list whitelist")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "List the countries that are allowed to play on the server.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "ini"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "load botman ini")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Make the bot reload the botman.ini file.  It only reloads when told to.")
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


	local function cmd_MendPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mend") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "mend {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Remove the brokenLeg buff from a player or yourself if no name given.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "mend") then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and can't catch a break.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and can't catch a break.")
				end

				botman.faultyChat = false
				return true
			end

			send("debuffplayer " .. id .. " sprainedLeg")
			send("debuffplayer " .. id .. " brokenLeg")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 2
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "move {player name} to {location}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport a player to a location. To teleport them to another player use the send command.")
					irc_chat(chatvars.ircAlias, "If the player is offline, they will be moved to the location when they next join.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
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
				players[id].location = loc

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name .. " will spawn at " .. locations[loc].name .. " next time they join.")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET location = '" .. loc .. "' WHERE steam = " .. id) end
			end

			players[id].xPosOld = locations[loc].x
			players[id].yPosOld = locations[loc].y
			players[id].zPosOld = locations[loc].z

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_NearPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "goto") or string.find(chatvars.command, "near") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "near {player name} {optional number}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport below and a short distance away from a player.  You must be flying for this or you will just fall all the time.")
					irc_chat(chatvars.ircAlias, "You arrive 20 metres below the player and 30 metres to the south.  If you give a number after the player name you will be that number metres south of them.")
					irc_chat(chatvars.ircAlias, "The bot will keep you near the player, teleporting you close to them if they get away from you.")
					irc_chat(chatvars.ircAlias, "To stop following them type " .. server.commandPrefix .. "stop.")
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

			if (players[chatvars.playerid].timeout == true) then
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")

				botman.faultyChat = false
				return true
			end

			igplayers[chatvars.playerid].following = id

			-- then teleport close to the player
			cmd = "tele " .. chatvars.playerid .. " " .. math.floor(igplayers[id].xPos) .. " " .. math.ceil(igplayers[id].yPos - 20) .. " " .. math.floor(igplayers[id].zPos - igplayers[chatvars.playerid].followDistance)
			send(cmd)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_PlayerIsNotNew()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "new") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "player {player name} is not new")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Upgrade a new player to a regular without making them wait for the bot to upgrade them. They will no longer be as restricted as a new player.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id ~= 0 then
				-- set the newPlayer flag to false
				players[id].newPlayer = false
				players[id].watchPlayer = false
				players[id].watchPlayerTimer = 0
				message("say [" .. server.chatColour .. "]" .. players[id].name .. " is no longer new here. Welcome back " .. players[id].name .. "! =D[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET newPlayer = 0, watchPlayer = 0, watchPlayerTimer = 0 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReadClaims()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "read claims")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "read claims")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Make the bot run llp so it knows where all the claims are and who owns them.")
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
			send("llp")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prison") or string.find(chatvars.command, "releas"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "release {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "just release {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Release a player from prison.  They are teleported back to where they were arrested.")
					irc_chat(chatvars.ircAlias, "Alternatively just release them so they do not teleport and have to walk back or use bot commands.")
					irc_chat(chatvars.ircAlias, "See also " .. server.commandPrefix .. "release here")
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
				message("say [" .. server.chatColour .. "]We don't have a prisoner called " .. prisoner .. ".[-]")

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if (chatvars.accessLevel > 2) then
					if (prisonerid == chatvars.playerid) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can't release yourself.  This isn't Idiocracy (except in Texas).[-]")
						botman.faultyChat = false
						return true
					end

					if (players[prisonerid].pvpVictim ~= chatvars.playerid) then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. prisoner .. " is not in prison for your death and cannot be released by you.[-]")
						botman.faultyChat = false
						return true
					end
				end
			end

			if (players[prisonerid].timeout == true or players[prisonerid].botTimeout == true) then
				players[prisonerid].timeout = false
				players[prisonerid].botTimeout = false
				players[prisonerid].freeze = false
				players[prisonerid].silentBob = false
				gmsg(server.commandPrefix .. "return " .. prisonerid)
				setChatColour(prisonerid)

				if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, prisoner = 0 WHERE steam = " .. prisonerid) end

				botman.faultyChat = false
				return true
			end

			if (not players[prisonerid].prisoner and players[prisonerid].timeout == false) then
				message("say [" .. server.chatColour .. "]Citizen " .. prisoner .. " is not a prisoner[-]")
				botman.faultyChat = false
				return true
			end

			players[prisonerid].xPosOld = 0
			players[prisonerid].yPosOld = 0
			players[prisonerid].zPosOld = 0

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
				if (players[prisonerid]) then
					players[prisonerid].location = "return player"
					message("say [" .. server.chatColour .. "]" .. players[prisonerid].name .. " will be released when they next join the server.[-]")

					players[prisonerid].xPosOld = players[prisonerid].prisonxPosOld
					players[prisonerid].yPosOld = players[prisonerid].prisonyPosOld
					players[prisonerid].zPosOld = players[prisonerid].prisonzPosOld

					if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 0, silentBob = 0, location = 'return player', xPosOld = " .. players[prisonerid].prisonxPosOld .. ", yPosOld = " .. players[prisonerid].prisonyPosOld .. ", zPosOld = " .. players[prisonerid].prisonzPosOld .. " WHERE steam = " .. prisonerid) end
				end
			end

			players[prisonerid].prisoner = false
			players[prisonerid].silentBob = false
			setChatColour(prisonerid)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReleasePlayerHere()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rele") or string.find(chatvars.command, "free") or string.find(chatvars.command, "pris"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "release here {prisoner}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Release a player from prison and move them to your location.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. prisoner)
				end

				botman.faultyChat = false
				return true
			end

			if (players[prisonerid].prisoner == false) then
				message("say [" .. server.chatColour .. "]Citizen " .. players[prisonerid].name .. " is not a prisoner[-]")
				botman.faultyChat = false
				return true
			end

			players[prisonerid].prisoner = false
			players[prisonerid].timeout = false
			players[prisonerid].botTimeout = false
			players[prisonerid].freeze = false
			players[prisonerid].silentBob = false

			if players[prisonerid].chatColour ~= "" then
				send("cpc " .. prisonerid .. " " .. players[prisonerid].chatColour .. " 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			else
				setChatColour(prisonerid)
			end

			if botman.dbConnected then conn:execute("UPDATE players SET prisoner=0,timeout=0,botTimeout=0,silentBob=0 WHERE steam = " .. prisonerid) end

			message("say [" .. server.chatColour .. "]Releasing prisoner " .. players[prisonerid].name .. "[-]")

			if (players[prisonerid].steam) then
				message("pm " .. prisonerid .. " [" .. server.chatColour .. "]You are released from prison.  Be a good citizen if you wish to remain free.[-]")
				cmd = "tele " .. prisonerid .. " " .. chatvars.playerid
				teleport(cmd, prisonerid)
				players[prisonerid].xPosOld = 0
				players[prisonerid].yPosOld = 0
				players[prisonerid].zPosOld = 0
				players[prisonerid].prisonxPosOld = 0
				players[prisonerid].prisonyPosOld = 0
				players[prisonerid].prisonzPosOld = 0
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ReloadAdmins()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "reload admins")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "reload admins")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Make the bot run admin list to reload the admins from the server's list.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "reload" or chatvars.words[1] == "refresh" or chatvars.words[1] == "update") and chatvars.words[2] == "admins" then
			-- run admin list
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reading admin list[-]")
			send("admin list")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemovePlayerClaims()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim") or string.find(chatvars.command, "keys"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "remove claims {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "The bot will automatically remove the player's claims whenever possible. The chunk has to be loaded and the bot takes several minutes to remove them but it will remove them.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id ~= 0 then
				-- flag the player's claims for removal
				players[id].removeClaims = true

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.[-]")
				else
					irc_chat(chatvars.ircAlias, "I will remove all of player " .. players[id].name .. "'s claims when their chunks are loaded.")
				end

				send("llp " .. id)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if botman.dbConnected then conn:execute("UPDATE players SET removeClaims = 1 WHERE steam = " .. id) end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayerTimers()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "timer"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "resettimers {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Normally a player needs to wait a set time after " .. server.commandPrefix .. "base before they can use it again. This zeroes that timer and also resets their gimmies.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "clear") or string.find(chatvars.command, "stack"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "reset stack")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "If you have changed stack sizes and the bot is mistakenly abusing players for overstacking, you can make the bot forget the stack sizes.")
					irc_chat(chatvars.ircAlias, "It will re-learn them from the server as players overstack beyond the new stack limits.")
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


	local function cmd_ReturnPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "return")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "return {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "return {player name} to {location or other player}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Return a player from timeout.  You can use their steam or game id and part or all of their name.")
					irc_chat(chatvars.ircAlias, "You can return them to any player even offline ones or to any location. If you just return them, they will return to wherever they were when they were sent to timeout.")
					irc_chat(chatvars.ircAlias, "Your regular players can also return new players from timeout but only if a player sent them there.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, tmp.pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				-- don't allow players to return anyone to a different location.
				if (chatvars.accessLevel > 2) then
					tmp.loc = nil
				end
			end

			if (players[tmp.id].timeout == true and tmp.id == chatvars.playerid and chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You are in timeout. You cannot release yourself.[-]")
				botman.faultyChat = false
				return true
			end

			if players[tmp.id].timeout == false and players[tmp.id].prisoner and ((tmp.id ~= chatvars.playerid and chatvars.accessLevel > 2) or chatvars.playerid == players[id].pvpVictim) then
				gmsg(server.commandPrefix .. "release " .. players[tmp.id].name)
				botman.faultyChat = false
				return true
			end

			if (chatvars.playername ~= "Server") then
				if chatvars.accessLevel > 2 then
					if players[tmp.id].newPlayer == true or players[tmp.id].timeout == false then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can only use this command on new players in timeout and a player sent them there.[-]")
						botman.faultyChat = false
						return true
					end
				end
			end

			-- return player to previously recorded x y z
			if (igplayers[tmp.id]) then
				if tonumber(players[tmp.id].yPosTimeout) > 0 then
					players[tmp.id].timeout = false
					players[tmp.id].botTimeout = false
					players[tmp.id].freeze = false
					players[tmp.id].silentBob = false

					igplayers[tmp.id].skipExcessInventory = true

					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
					else
						send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " " .. players[tmp.id].yPosTimeout .. " " .. players[tmp.id].zPosTimeout)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

						players[tmp.id].xPosTimeout = 0
						players[tmp.id].yPosTimeout = 0
						players[tmp.id].zPosTimeout = 0

						if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id) end

						message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")

						botman.faultyChat = false
						return true
					end

					teleport(tmp.cmd, tmp.id)

					players[tmp.id].xPosTimeout = 0
					players[tmp.id].yPosTimeout = 0
					players[tmp.id].zPosTimeout = 0

					if tmp.loc ~= nil then
						message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
					else
						message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
					end

					if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0, xPosTimeout = 0, yPosTimeout = 0, zPosTimeout = 0 WHERE steam = " .. tmp.id) end

					botman.faultyChat = false
					return true
				end

				if tonumber(players[tmp.id].yPosOld) > 0 then
					players[tmp.id].timeout = false
					players[tmp.id].botTimeout = false

					if tmp.loc ~= nil then
						tmp.cmd = "tele " .. tmp.id .. " " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z
					else
						tmp.cmd = "tele " .. tmp.id .. " " .. players[tmp.id].xPosOld .. " " .. players[tmp.id].yPosOld .. " " .. players[tmp.id].zPosOld
					end

					teleport(tmp.cmd, tmp.id)

					players[tmp.id].xPosOld = 0
					players[tmp.id].yPosOld = 0
					players[tmp.id].zPosOld = 0

					if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, botTimeout = 0, xPosOld = 0, yPosOld = 0, zPosOld = 0 WHERE steam = " .. tmp.id) end

					if tmp.loc ~= nil then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
						else
							message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. " to " .. tmp.loc .. "[-]")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
						else
							message("say [" .. server.chatColour .. "]Returning " .. players[tmp.id].name .. "[-]")
						end
					end
				end
			else
				if (players[tmp.id].yPosTimeout) then
					players[tmp.id].timeout = false
					players[tmp.id].botTimeout = false
					players[tmp.id].location = "return player"
					players[tmp.id].silentBob = false

					message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " will be returned when they next join the server.[-]")

					if botman.dbConnected then conn:execute("UPDATE players SET timeout = 0, silentBob = 0, botTimeout = 0 WHERE steam = " .. tmp.id) end

					botman.faultyChat = false
					return true
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SendPlayerHome()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "home") or string.find(chatvars.command, "player") or string.find(chatvars.command, "send"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "sendhome {player name} or " .. server.commandPrefix .. "sendhome2 {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport a player to their first or second base.")
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

				if (id == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No in-game players found with that name.[-]")
					else
						irc_chat(chatvars.ircAlias, "No in-game players found called " .. pname)
					end

					botman.faultyChat = false
					return true
				end

				if (accessLevel(id) < 3) then
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
					players[id].xPosOld = math.floor(igplayers[id].xPos)
					players[id].yPosOld = math.ceil(igplayers[id].yPos)
					players[id].zPosOld = math.floor(igplayers[id].zPos)
				end

				if (chatvars.words[1] == "sendhome") then
					if (players[id].homeX == 0 and players[id].homeZ == 0) then
						if server.coppi then
							prepareTeleport(id, "")
							send("teleh " .. id)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end

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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "send") or string.find(chatvars.command, "player") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "send {player1} to {player2}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport a player to another player even if the other player is offline.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname1 .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname1 .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if id2 == 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname2 .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname2 .. " did not match any players.")
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
				players[id1].xPosOld = math.floor(players[id1].xPos)
				players[id1].yPosOld = math.floor(players[id1].yPos)
				players[id1].zPosOld = math.floor(players[id1].zPos)

				if (igplayers[id2]) then
					cmd = "tele " .. id1 .. " " .. id2
					teleport(cmd, id1)
				else
					cmd = "tele " .. id1 .. " " .. math.floor(players[id2].xPos) .. " " .. math.ceil(players[id2].yPos) .. " " .. math.floor(players[id2].zPos)
					teleport(cmd, id1)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetFeralRebootDelay()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "feral") or string.find(chatvars.command, "rebo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "feral reboot delay {minutes}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Set how many minutes after day 7 that the bot will wait before rebooting if a reboot is scheduled for day 7.")
					irc_chat(chatvars.ircAlias, "To disable this feature, set it to 0.  The bot will wait a full game day instead.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "maint") or string.find(chatvars.command, "track") or string.find(chatvars.command, "set"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "max tracking days {days}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Set how many days to keep tracking data before deleting it.  The default it 28.")
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


	local function cmd_SetReturnCooldown()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "return") or string.find(chatvars.command, "cool") or string.find(chatvars.command, "delay") or string.find(chatvars.command, "time"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set return cooldown {seconds} (default 0)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "You can add a delay to the return command.  Does not affect staff.")
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


	local function cmd_SetViewArrestReason()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "prisoner") or string.find(chatvars.command, "arrest"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "prisoner {player name} arrested {reason for arrest}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "prisoner {player name} (read the reason if one is recorded)")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "You can record or view the reason for a player being arrested.  If they are released, this record is destroyed.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "prisoner") then
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

			reason = nil

			if string.find(chatvars.command, "arrested") then
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9, string.find(chatvars.command, "arrested") -1)
				reason = string.sub(chatvars.command, string.find(chatvars.command, "arrested ") + 9)
			else
				prisoner = string.sub(chatvars.command, string.find(chatvars.command, "prisoner ") + 9)
			end

			prisoner = stripQuotes(string.trim(prisoner))
			prisonerid = LookupPlayer(prisoner)
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
				if reason ~= nil then
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
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. prisoner .. " was arrested for " .. players[prisonerid].prisonReason .. "[-]")
						else
							irc_chat(chatvars.ircAlias, prisoner .. " was arrested for " .. players[prisonerid].prisonReason)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] No reason is recorded for " .. prisoner .. "'s arrest.[-]")
						else
							irc_chat(chatvars.ircAlias, "No reason is recorded for " .. prisoner .. "'s arrest.")
						end
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ShitPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "shit") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "shit {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give a player the shits for shits and giggles.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "shit" and chatvars.words[2] ~= nil) then
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
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
					end

					botman.faultyChat = false
					return true
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

			r = rand(10)

			send("buffplayer " .. id .. " dysentery")

			for i = 1, r do
				send("give " .. igplayers[id].id .. " turd 1")
			end

			message("pm " .. id .. " [" .. server.chatColour .. "]Hey " .. players[id].name .. "! You dropped something.[-]")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 2
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "test") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "remo"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "test as player")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Remove your admin status for 5 minutes.  It will be automatically restored.")
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
				irc_chat(chatvars.ircAlias, "This command is ingame only.")
				botman.faultyChat = false
				return true
			end

			local cmd

			cmd = string.format("ban remove %s", chatvars.playerid)
			if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 299) .. "')") end

			cmd = string.format("admin add %s %s", chatvars.playerid, chatvars.accessLevel)
			if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 300) .. "')") end

			cmd = string.format("pm %s [%s]Your admin status is restored.[-]", chatvars.playerid, server.chatColour)
			if botman.dbConnected then conn:execute("insert into miscQueue (steam, command, timerDelay) values (" .. chatvars.playerid .. ",'" .. escape(cmd) .. "','" .. os.date("%Y-%m-%d %H:%M:%S", os.time() + 301) .. "')") end

			send("admin remove " .. chatvars.playerid)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			message(string.format("pm %s [%s]Your admin status has been temporarily removed.  You are now a player.  You will regain admin in 5 minutes.  Good luck![-]", chatvars.playerid, server.chatColour))

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_TimeoutPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and string.find(chatvars.command, "timeout")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "timeout {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Send a player to timeout.  You can use their steam or game id and part or all of their name.  If you send the wrong player to timeout " .. server.commandPrefix .. "return {player name} to fix that.")
					irc_chat(chatvars.ircAlias, "While in timeout, the player will not be able to use any bot commands but they can chat.")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You can also send yourself to timeout but not other staff.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "timeout {player name}[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]See also: " .. server.commandPrefix .. "return {player name}[-]")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "timeout ") + 8)
			tmp.pname = string.trim(tmp.pname)
			tmp.id = LookupPlayer(tmp.pname)

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
			players[tmp.id].xPosTimeout = math.floor(players[tmp.id].xPos)
			players[tmp.id].yPosTimeout = math.ceil(players[tmp.id].yPos)
			players[tmp.id].zPosTimeout = math.floor(players[tmp.id].zPos)

			if (chatvars.playername ~= "Server") then
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.playerid].name) .. "'," .. tmp.id .. ")") end
			else
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. players[tmp.id].xPosTimeout .. "," .. players[tmp.id].yPosTimeout .. "," .. players[tmp.id].zPosTimeout .. ",'" .. botman.serverTime .. "','timeout','Player " .. escape(players[tmp.id].name) .. " SteamID: " .. tmp.id .. " sent to timeout by " .. escape(players[chatvars.ircid].name) .. "'," .. tmp.id .. ")") end
			end

			-- then teleport the player to timeout
			send("tele " .. tmp.id .. " " .. players[tmp.id].xPosTimeout .. " 50000 " .. players[tmp.id].zPosTimeout)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			message("say [" .. server.chatColour .. "]" .. players[tmp.id].name .. " has been sent to timeout.[-]")

			if botman.dbConnected then conn:execute("UPDATE players SET timeout = 1, silentBob = 1, xPosTimeout = " .. players[tmp.id].xPosTimeout .. ", yPosTimeout = " .. players[tmp.id].yPosTimeout .. ", zPosTimeout = " .. players[tmp.id].zPosTimeout .. " WHERE steam = " .. tmp.id) end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleAirdropAlert()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "air"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable (or enable) airdrop alert")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "By default the bot will inform players when an airdrop occurs near them.  You can disable the message.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "block player {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "unblock player {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Prevent a player from using IRC.  Other stuff may be blocked in the future.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if (players[id]) then
				if chatvars.words[1] == "block" then
					players[id].denyRights = true
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 1 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " will be ignored on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[id].name .. " will be ignored on IRC.")
					end
				else
					players[id].denyRights = false
					if botman.dbConnected then conn:execute("UPDATE players SET denyRights = 0 WHERE steam = " .. id) end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " can talk to the bot on IRC.[-]")
					else
						irc_chat(chatvars.ircAlias,players[id].name .. " can talk to the bot on IRC.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleBounties()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "bounty")) or string.find(chatvars.command, "pvp")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable (or enable) bounty")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Normally a small bounty is awarded for a player's first pvp kill in pvp rules.  You can disable the automatic bounty.")
					irc_chat(chatvars.ircAlias, "Players will still be able to manually place bounties, but those come out of their " .. server.moneyPlural .. ".")
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


	local function cmd_ToggleClaimScan()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "claim"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable (or enable) claim scan")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Every 45 seconds the bot reads the claims of all ingame players. This can be a lot of data and could impact server performance.")
					irc_chat(chatvars.ircAlias, "If the bot is reporting server lag frequently, you can disable the timed claim scan.")
					irc_chat(chatvars.ircAlias, "It will still scan when a player leaves the server and can be commanded to do a scan.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "disable" or chatvars.words[1] == "enable") and chatvars.words[2] == "claim" and chatvars.words[3] == "scan" then
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
				server.enableTimedClaimScan = 0
				conn:execute("UPDATE server SET enableTimedClaimScan = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Claims will not be scanned every minute.[-]")
				else
					irc_chat(chatvars.ircAlias, "Claims will not be scanned every minute.")
				end
			else
				server.enableTimedClaimScan = 1
				conn:execute("UPDATE server SET enableTimedClaimScan = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Claims of ingame players (except admins) will be scanned every minute. This can produce a lot of data and may impact server performance.[-]")
				else
					irc_chat(chatvars.ircAlias, "Claims of ingame players (except admins) will be scanned every minute. This can produce a lot of data and may impact server performance.")
				end
			end

			irc_chat(chatvars.ircAlias, ".")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleFreezeThawPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "freeze") or string.find(chatvars.command, "player") or string.find(chatvars.command, "stop"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "freeze/unfreeze {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Bind a player to their current position.  They get teleported back if they move.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
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
				players[id].prisonxPosOld = math.floor(players[id].xPos)
				players[id].prisonyPosOld = math.ceil(players[id].yPos)
				players[id].prisonzPosOld = math.floor(players[id].zPos)
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "ignore/punish friendly pvp")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "By default if a player PVPs where the rules don't permit it, they can get jailed.")
					irc_chat(chatvars.ircAlias, "You can tell the bot to ignore friendly kills.  Players must have friended the victim before the PVP occurs.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "player") or string.find(chatvars.command, "excl") or string.find(chatvars.command, "igno"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "ignore/include player {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "An ignored player can have uncraftable inventory and do hacker like activity such as teleporting and flying.")
					irc_chat(chatvars.ircAlias, "An included player is checked for these things and can be punished or temp banned for them.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "ignore" then
				players[id].ignorePlayer = true

				if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 1 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.[-]")
				else
					irc_chat(chatvars.ircAlias,players[id].name .. " is allowed to carry uncraftable items, fly, teleport and other fun stuff.")
				end
			else
				players[id].ignorePlayer = false

				if botman.dbConnected then conn:execute("UPDATE players SET ignorePlayer = 0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.[-]")
				else
					irc_chat(chatvars.ircAlias,players[id].name .. " is not allowed to carry uncraftable items, fly or teleport and can be temp banned or made fun of.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleIncludeExcludeAdmins()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "clude") or string.find(chatvars.command, "admin") or string.find(chatvars.command, "rule"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "exclude/include admins")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Normally the bot ignores admins when checking inventory and other stuff.  If admins are included, all of the rules that apply to players will also apply to admins.")
					irc_chat(chatvars.ircAlias, "This is useful for testing the bot.  You can also use " .. server.commandPrefix .. "test as player (for 5 minutes)")
					irc_chat(chatvars.ircAlias, "This setting is not stored and will revert to excluding admins the next time the bot runs.")
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "able") or string.find(chatvars.command, "pack") or string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "enable/disable pack/revive")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Players can teleport close to where they last died to retrieve their pack.")
					irc_chat(chatvars.ircAlias, "You can disable the pack and revive commands.  They are enabled by default.")
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


	local function cmd_ToggleReservedSlotPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "slot") or string.find(chatvars.command, "player") or string.find(chatvars.command, "rese"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "reserve/unreserve slot {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Give a player the right to take a reserved slot when the server is full.")
					irc_chat(chatvars.ircAlias, "Reserved slots are auto assigned for donors and staff.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "reserve" then
				players[id].reserveSlot = true
				if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 1 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " can take a reserved slot when the server is full.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name ..  " can take a reserved slot when the server is full.")
				end
			else
				players[id].reserveSlot = false
				if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 0 WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " can only reserve a slot if they are a donor or staff.[-]")
				else
					irc_chat(chatvars.ircAlias, "Player " .. players[id].name ..  " can only reserve a slot if they are a donor or staff.")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET reserveSlot = 1 WHERE steam = " .. id) end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleScreamerAlert()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "scream"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "disable (or enable) screamer alert")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "By default the bot will warn players when screamers are approaching.  You can disable that warning.")
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
				server.enableScreamerAlert = 0
				conn:execute("UPDATE server SET enableScreamerAlert = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The screamer alert message is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The screamer alert message is disabled.")
				end
			else
				enableTrigger("Zombie Scouts")
				server.enableScreamerAlert = 1
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "allow/disallow teleport {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Allow or prevent a player from using any teleports.  When disabled, they won't be able to teleport themselves, but they can still be teleported.  Also physical teleports won't work for them.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "disallow" then
				players[id].canTeleport = false
				message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is not allowed to use teleports.[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 0 WHERE steam = " .. id) end
			else
				players[id].canTeleport = true
				message("say [" .. server.chatColour .. "] " .. players[id].name ..  " is allowed to use teleports.[-]")

				if botman.dbConnected then conn:execute("UPDATE players SET canTeleport = 1 WHERE steam = " .. id) end

			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWatchPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "watch") or string.find(chatvars.command, "player") or string.find(chatvars.command, "new"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "watch {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "watch new players")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "stop watching {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "stop watching everyone")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Flag a player or all current new players for extra attention and logging.  New players are watched by default.")
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
						v.watchPlayerTimer = os.time() + 2419200 -- 1 month or until not new
						if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 2419200 .. " WHERE steam = " .. k) end
					end
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New players will be watched.[-]")

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "watch") then
				pname = string.sub(chatvars.command, string.find(chatvars.command, "watch ") + 6)
				pname = string.trim(pname)
				id = LookupPlayer(pname)

				if id == 0 then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
					end

					botman.faultyChat = false
					return true
				end

				players[id].watchPlayer = true
				players[id].watchPlayerTimer = os.time() + 259200 -- 3 days
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admins will be alerted whenever " .. players[id].name ..  " enters a base.[-]")
				end

				if botman.dbConnected then conn:execute("UPDATE players SET watchPlayer = 1, watchPlayerTimer = " .. os.time() + 259200 .. " WHERE steam = " .. id) end
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
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
					else
						irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
					end

					botman.faultyChat = false
					return true
				end

				players[id].watchPlayer = false
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. players[id].name ..  " will no longer be watched.[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleWaypoints()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "way"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "enable/disable waypoints")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Donors will be able to create, use and share waypoints.  To enable them for other players, set waypoints public.")
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


	local function cmd_VisitCrimescene()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "pvp") or string.find(chatvars.command, "death") or string.find(chatvars.command, "crime"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "crimescene {prisoner}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport to the coords where a player was when they got arrested.")
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. prisoner .. "[-]")

				botman.faultyChat = false
				return true
			end

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

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_VisitPlayerBase()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "tele") or string.find(chatvars.command, "home") or string.find(chatvars.command, "base") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "playerbase {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "playerhome {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "playerbase2 {player name}")
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "playerhome2 {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Teleport yourself to the first or second base of a player.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. pname .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "No player found matching " .. pname)
				end

				botman.faultyChat = false
				return true
			end

			if (chatvars.words[1] == "playerhome" or chatvars.words[1] == "playerbase") then
				if (players[id].homeX == 0 and players[id].homeZ == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a base yet.[-]")
					botman.faultyChat = false
					return true
				else
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = math.floor(igplayers[chatvars.playerid].xPos)
					players[chatvars.playerid].yPosOld = math.ceil(igplayers[chatvars.playerid].yPos)
					players[chatvars.playerid].zPosOld = math.floor(igplayers[chatvars.playerid].zPos)

					cmd = "tele " .. chatvars.playerid .. " " .. players[id].homeX .. " " .. players[id].homeY .. " " .. players[id].homeZ
					teleport(cmd, chatvars.playerid)
				end
			else
				if (players[id].home2X == 0 and players[id].home2Z == 0) then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " Has not set a 2nd base yet.[-]")
					botman.faultyChat = false
					return true
				else
					-- first record the current x y z
					players[chatvars.playerid].xPosOld = math.floor(igplayers[chatvars.playerid].xPos)
					players[chatvars.playerid].yPosOld = math.ceil(igplayers[chatvars.playerid].yPos)
					players[chatvars.playerid].zPosOld = math.floor(igplayers[chatvars.playerid].zPos)

					cmd = "tele " .. chatvars.playerid .. " " .. players[id].home2X .. " " .. players[id].home2Y .. " " .. players[id].home2Z
					teleport(cmd, chatvars.playerid)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_WarmPlayer()
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "warm") or string.find(chatvars.command, "player"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "warm {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Warm a player or yourself if no name given.")
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "warm") then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. igplayers[id].name .. " is not playing right now and is left out in the cold.[-]")
				else
					irc_chat(chatvars.ircAlias, igplayers[id].name .. " is not playing right now and is left out in the cold.")
				end

				botman.faultyChat = false
				return true
			end

			send("buffplayer " .. id .. " stewWarming")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
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
		if chatvars.showHelp and not skipHelp then
			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "white"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "whitelist add/remove {player name}")

				if not shortHelp then
					irc_chat(chatvars.ircAlias, "Add (or remove) a player to the bot's whitelist. This is not the server's whitelist and it works differently.")
					irc_chat(chatvars.ircAlias, "It exempts the player from bot restrictions such as ping kicks and the country blacklist.")
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
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. pname .. " did not match any players.[-]")
				else
					irc_chat(chatvars.ircAlias, pname .. " did not match any players.")
				end

				botman.faultyChat = false
				return true
			end

			if chatvars.words[2] == "add" then
				whitelist[id] = {}
				if botman.dbConnected then conn:execute("INSERT INTO whitelist (steam) VALUES (" .. id .. ")") end

				send("ban remove " .. id)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " has been added to the whitelist.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " has been added to the whitelist.")
				end
			else
				whitelist[id] = nil
				if botman.dbConnected then conn:execute("DELETE FROM whitelist WHERE steam = " .. id) end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "] " .. players[id].name .. " is no longer whitelisted.[-]")
				else
					irc_chat(chatvars.ircAlias, players[id].name .. " is no longer whitelisted.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

if debug then dbug("debug admin") end

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

	if (debug) then dbug("debug admin line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleClaimScan()

	if result then
		if debug then dbug("debug cmd_ToggleClaimScan triggered") end
		return result
	end

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

	result = cmd_VisitCrimescene()

	if result then
		if debug then dbug("debug cmd_VisitCrimescene triggered") end
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

	if debug then dbug("debug admin end") end

	-- can't touch dis
	if true then
		return result
	end
end
