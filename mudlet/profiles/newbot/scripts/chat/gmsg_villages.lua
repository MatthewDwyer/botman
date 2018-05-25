--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local debug, result, pid, vid, name1, villageName, r, pname, cursor1, cursor2, errorString, help, tmp
local shortHelp = false
local skipHelp = false

debug = false -- should be false unless testing

if botman.debugAll then
	debug = true -- this should be true
end

function gmsg_villages()
	calledFunction = "gmsg_villages"
	result = false
	tmp = {}

-- ################## village command functions ##################

	local function cmd_AddVillage()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add village {village name}"
			help[2] = "Create a new village."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,add,crea"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "add") or string.find(chatvars.command, "vill") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" and chatvars.words[2] == "village") then
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
	end


	local function cmd_AddVillageMember()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}add member {player name} village {village}"
			help[2] = "Add a player as a member of a village."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,add,play,memb"
				tmp.accessLevel = 99
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0

				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or string.find(chatvars.command, "add") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "add" and chatvars.words[2] == "member") then
			if (string.find(chatvars.command, "village")) then
				name1 = string.sub(chatvars.command, string.find(chatvars.command, "member") + 7, string.find(chatvars.command, "village") - 1)
				name1 = string.trim(name1)

				pid = LookupPlayer(name1)

				if pid == 0 then
					pid = LookupArchivedPlayer(name1)

					if not (pid == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. name1 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. name1)
						end
					end
				end

				villageName = string.sub(chatvars.command, string.find(chatvars.command, "village") + 8)
				villageName = string.trim(villageName)

				if (chatvars.playername ~= "Server") then
					if (chatvars.accessLevel > 2) and (locations[villageName].mayor ~= chatvars.playerid) then
						message(string.format("pm %s [%s]" .. restrictedCommandMessage(), chatvars.playerid, server.chatColour))
						botman.faultyChat = false
						return true
					end
				else
					if (chatvars.accessLevel > 2) and (locations[villageName].mayor ~= chatvars.ircid) then
						irc_chat(chatvars.ircAlias, "This command is restricted.")
						botman.faultyChat = false
						return true
					end
				end

				vid = LookupLocation(villageName)
				if vid == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "There is no village called " .. villageName)
					end

					botman.faultyChat = false
					return true
				end

				if locations[vid].village ~= true then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. villageName .. " is not a village.[-]")
					else
						irc_chat(chatvars.ircAlias, villageName .. " is not a village.")
					end

					botman.faultyChat = false
					return true
				end

				if (pid ~= 0) then
					conn:execute("INSERT INTO villagers SET steam = " .. pid .. ", village = '" .. escape(villageName) .. "'")

					villagers[pid .. vid] = {}
					villagers[pid .. vid].village = villageName

					message("say [" .. server.chatColour .. "]" .. players[pid].name .. " is now a member of " .. villageName .. " village.[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, players[pid].name .. " is now a member of " .. villageName .. " village.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ElectMayor()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}elect {player name} village {village}"
			help[2] = "Elect a player as mayor of a village.  Democratically of course :)"

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,add,play,elect,mayor"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or string.find(chatvars.command, "elect") or string.find(chatvars.command, "mayo") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "elect" and chatvars.words[2] ~= nil) then
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
						irc_chat(chatvars.ircAlias, "There is no village called " .. villageName)
					end

					botman.faultyChat = false
					return true
				end

				if pid == 0 then
					pid = LookupArchivedPlayer(name1)

					if not (pid == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. name1 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. name1)
						end
					end
				end

				if (pid ~= 0) then
					if locations[villageName] ~= nil then
						locations[villageName].mayor = pid
						locations[villageName].owner = pid
						locations[villageName].village = true
						message("say [" .. server.chatColour .. "]Congratulations " .. players[pid].name .. " on becoming the new mayor of " .. villageName .. "[-]")

						r = rand(5)

						if r == 1 then message("say [" .. server.chatColour .. "]The best village in all the land![-]") end
						if r == 2 then message("say [" .. server.chatColour .. "]Now you can show those home owner associations how it's really done![-]") end
						if r == 3 then message("say [" .. server.chatColour .. "]GLORY TO " .. string.upper(villageName) .. "![-]") end
						if r == 4 then message("say [" .. server.chatColour .. "]Have fun sorting out all the spats, petty squabbles, and other fun social misadventures xD[-]") end
						if r == 5 then message("say [" .. server.chatColour .. "]Now add surfs, slaves, wenches and someone to put the bottles out.[-]") end

						conn:execute("UPDATE locations SET village = 1, mayor = " .. pid .. ", owner = " .. pid .. " WHERE name = '" .. escape(villageName) .. "'")
						conn:execute("INSERT INTO villagers SET steam = " .. pid .. ", village = '" .. escape(villageName) .. "'")

						villagers[pid .. vid] = {}
						villagers[pid .. vid].village = villageName
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_List()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}villages\n"
			help[1] = help[1] .. " {#}villagers"
			help[2] = "List villages or villagers."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,add,play,elect,mayor"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "villages" and chatvars.words[2] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]List of villages:[-]")

			for k, v in pairs(locations) do
				if (v.village == true) then
					pid = 0

					if v.mayor ~= 0 then
						pid = LookupOfflinePlayer(v.mayor)
					end

					if pid ~= 0 then
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
	end


	local function cmd_ProtectVillage()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}protect village {village name}"
			help[2] = "Set village protection and follow the prompt from the bot, just like setting base protection."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,prot,set"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "prot") or string.find(chatvars.command, "vill") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "protect" and chatvars.words[2] == "village" and chatvars.words[3] ~= nil) then
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
	end


	local function cmd_RemoveVillage()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove village {village}"
			help[2] = "Delete a village and everything associated with it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,remo,dele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or string.find(chatvars.command, "remo") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "remove" and chatvars.words[2] == "village") then
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

			villageName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "village ") + 8))

			vid = LookupLocation(villageName)
			if vid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "There is no village called " .. villageName)
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

			message("say [" .. server.chatColour .. "]A village called " .. vid .. " has been removed.[-]")

			if (chatvars.playername ~= "Server") then
				irc_chat(chatvars.ircAlias, "A village called " .. vid .. " has been removed.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveVillageMember()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}remove member {player name} village {village}"
			help[2] = "Remove a player from a village."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,remo,dele"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or string.find(chatvars.command, "remo") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

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
				else
					if (chatvars.accessLevel > 2) and (locations[villageName].mayor ~= chatvars.ircid) then
						irc_chat(chatvars.ircAlias, "This command is restricted.")
						botman.faultyChat = false
						return true
					end
				end

				vid = LookupLocation(villageName)
				if vid == nil then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "There is no village called " .. villageName)
					end

					botman.faultyChat = false
					return true
				end

				if pid == 0 then
					pid = LookupArchivedPlayer(name1)

					if not (pid == 0) then
						conn:execute("DELETE FROM villagers WHERE village = '" .. escape(vid) .. "' and steam = " .. pid)
						villagers[pid .. vid] = nil
						message("say [" .. server.chatColour .. "]" .. playersArchived[pid].name .. " has been cast out of village " .. vid .. "[-]")

						if (chatvars.playername ~= "Server") then
							irc_chat(chatvars.ircAlias, playersArchived[pid].name .. " has been cast out of village " .. vid)
						end

						botman.faultyChat = false
						return true
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. name1 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found called " .. name1)
						end
					end
				else
					conn:execute("DELETE FROM villagers WHERE village = '" .. escape(vid) .. "' and steam = " .. pid)
					villagers[pid .. vid] = nil
					message("say [" .. server.chatColour .. "]" .. players[pid].name .. " has been cast out of village " .. vid .. "[-]")

					if (chatvars.playername ~= "Server") then
						irc_chat(chatvars.ircAlias, players[pid].name .. " has been cast out of village " .. vid)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_RemoveVillageProtection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}unprotect village {village name}"
			help[2] = "Remove protection on a village."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,remo,prot"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "prot") or string.find(chatvars.command, "vill") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "unprotect" and (chatvars.words[2] == "village") and chatvars.words[3] ~= nil) then
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
					locations[pname].protected = false
					conn:execute("UPDATE locations SET protected = 0 WHERE name = '" .. escape(pname) .. "'")
					message("say [" .. server.chatColour .. "]Protection has been removed from " .. pname .. ".[-]")
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You need to tell me the name of the village you are removing protection from.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetVillageSize()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}village {village} size {metres}"
			help[2] = "Resize a village. Note that this removes village protection to prevent teleport loops."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "vill,remo,prot"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if string.find(chatvars.command, "vill") or string.find(chatvars.command, "size") or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "village") then
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

			villageName = string.trim(string.sub(chatvars.command, string.find(chatvars.command, "village ") + 8, string.find(chatvars.command, "size") - 1))
			vid = LookupLocation(villageName)

			if vid == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]There is no village called " .. villageName .. "[-]")
				else
					irc_chat(chatvars.ircAlias, "There is no village called " .. villageName)
				end

				botman.faultyChat = false
				return true
			end

			if (locations[vid]) then
				locations[vid].size = math.floor(tonumber(chatvars.number))
				conn:execute("UPDATE locations set size = " .. locations[vid].size .. ", protected=0, protectSize = " .. locations[vid].size .. " WHERE name = '" .. escape(vid) .. "'")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. vid .. " is now " .. locations[vid].size .. " meters wide from its centre.[-]")
				else
					irc_chat(chatvars.ircAlias, vid .. " is now " .. locations[vid].size .. " meters wide from its centre.")
				end

				if locations[vid].protected then
					locations[vid].protected = false

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You must re-protect " .. vid .. " as its protection has been disabled due to the size change.[-]")
					else
						irc_chat(chatvars.ircAlias, "You must re-protect " .. vid .. " ingame as its protection has been disabled due to the size change.")
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - village commands ====")
		dbug("Registering help - village commands")

		tmp = {}
		tmp.topicDescription = "Villages work like protected bases except that they can have many players (villagers) and a mayor.\n"
		tmp.topicDescription = tmp.topicDescription .. "Just like a base, a village can have protection enabled.  Villages work best when they are much larger than the area of the village so that an effective barrier against invading players exists."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'villages'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('villages', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

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
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Village Commands:")
		irc_chat(chatvars.ircAlias, "=================")
		irc_chat(chatvars.ircAlias, ".")
		irc_chat(chatvars.ircAlias, "Villages work like protected bases except that they can have many players (villagers) and a mayor.")
		irc_chat(chatvars.ircAlias, "Just like a base, a village can have protection enabled.  Villages work best when they are much larger than the area of the village so that an effective barrier against invading players exists.")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "villages")
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddVillageMember()

	if result then
		if debug then dbug("debug cmd_AddVillageMember triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_ElectMayor()

	if result then
		if debug then dbug("debug cmd_ElectMayor triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_List()

	if result then
		if debug then dbug("debug cmd_List triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveVillage()

	if result then
		if debug then dbug("debug cmd_RemoveVillage triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveVillageMember()

	if result then
		if debug then dbug("debug cmd_RemoveVillageMember triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetVillageSize()

	if result then
		if debug then dbug("debug cmd_SetVillageSize triggered") end
		return result
	end

	if debug then dbug("debug villages end of remote commands") end

	-- ###################  do not run remote commands beyond this point unless displaying command help ################
	if chatvars.playerid == 0 and not (chatvars.showHelp or botman.registerHelp) then
		botman.faultyChat = false
		return false
	end
	-- ###################  do not run remote commands beyond this point unless displaying command help ################

	result = cmd_AddVillage()

	if result then
		if debug then dbug("debug cmd_AddVillage triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_ProtectVillage()

	if result then
		if debug then dbug("debug cmd_ProtectVillage triggered") end
		return result
	end

	if (debug) then dbug("debug villages line " .. debugger.getinfo(1).currentline) end

	result = cmd_RemoveVillageProtection()

	if result then
		if debug then dbug("debug cmd_RemoveVillageProtection triggered") end
		return result
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Village commands help registered ****")
		dbug("Village commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug villages end") end

	-- can't touch dis
	if true then
		return result
	end
end
