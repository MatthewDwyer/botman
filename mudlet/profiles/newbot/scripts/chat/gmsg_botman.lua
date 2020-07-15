--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local shortHelp = false
local skipHelp = false
local tmp = {}
local debug, result, prefabID

debug = false -- should be false unless testing

function gmsg_botman()
	calledFunction = "gmsg_botman"
	result = false

	if botman.debugAll then
		debug = true -- this should be true
	end

	prefabID = ""

-- ################## Botman mod command functions ##################

	-- Fisher-Yates shuffle from http://santos.nfshost.com/shuffling.html
	local function shuffle(t)
	  for i = 1, #t - 1 do
		local r = math.random(i, #t)
		t[i], t[r] = t[r], t[i]
	  end
	end

	-- builds a width-by-height grid of trues
	local function initialize_grid(w, h)
	  local a = {}
	  for i = 1, h do
		table.insert(a, {})
		for j = 1, w do
		  table.insert(a[i], true)
		end
	  end
	  return a
	end

	-- average of a and b
	local function avg(a, b)
	  return (a + b) / 2
	end


	local dirs = {
	  {x = 0, y = -2}, -- north
	  {x = 2, y = 0}, -- east
	  {x = -2, y = 0}, -- west
	  {x = 0, y = 2}, -- south
	}

	local function makeMaze(w, h, xPos, yPos, zPos, wall, fill, tall)
	  w = w or 16
	  h = h or 8

	  local map = initialize_grid(w*2+1, h*2+1)
	  local cmd

	  math.randomseed( os.time() )

	  local function walk(x, y)
		map[y][x] = false

		local d = { 1, 2, 3, 4 }
		shuffle(d)
		for i, dirnum in ipairs(d) do
		  local xx = x + dirs[dirnum].x
		  local yy = y + dirs[dirnum].y
		  if map[yy] and map[yy][xx] then
			map[avg(y, yy)][avg(x, xx)] = false
			walk(xx, yy)
		  end
		end
	  end

	  walk(math.random(1, w)*2, math.random(1, h)*2)

	  local s = {}
	  for i = 1, h*2+1 do
		for j = 1, w*2+1 do
		  if map[i][j] then
			--cmd = "bm-pblock " .. wall .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. " 0"
			--if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
		  else
			cmd = "bm-pblock " .. fill .. " " .. xPos + i .. " " .. xPos + i .. " " .. yPos .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j .. " 0"
			--cmd = "bm-pblock " .. fill .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. " 0"
			if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
		  end
		end
	  end
	end

	local function renderMaze(wallBlock, x, y, z, width, length, height, fillBlock, roof, levels, i)
		local k, v, mazeX, mazeZ, block, maze, cmd

		if levels > 1 then
			for i = 1, levels do
				cmd = "bm-pblock " .. wallBlock .. " " .. x .. " " .. x + (width * 2) + 2 .. " " .. y .. " " .. y + height - 1 .. " " .. z .. " " .. z + (length * 2) + 2 .. " 0"
				if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
				makeMaze(width, length, x, y, z, wallBlock, fillBlock, height)

				y = y + height

				cmd = "bm-pblock " .. wallBlock .. " " .. x .. " " .. x + (width * 2) + 2 .. " " .. y .. " " .. y .. " " .. z .. " " .. z + (length * 2) + 2 .. " 0"
				if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end

				y = y + 1
			end
		else
			if roof then
				cmd = "bm-pblock " .. wallBlock .. " " .. x .. " " .. x + (width * 2) + 2 .. " " .. y .. " " .. y + height .. " " .. z .. " " .. z + (length * 2) + 2 .. " 0"
			else
				cmd = "bm-pblock " .. wallBlock .. " " .. x .. " " .. x + (width * 2) + 2 .. " " .. y .. " " .. y + height - 1 .. " " .. z .. " " .. z + (length * 2) + 2 .. " 0"
			end

			if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
			makeMaze(width, length, x, y, z, wallBlock, fillBlock, height)
		end
	end

	local function cmd_AddRemoveTraderProtection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}trader protect/unprotect/remove {named area}\n"
			help[1] = " {#}trader add/trader del {named area}"
			help[2] = "After marking out a named area with the {#}mark command, you can add or remove trader protection on it.\n"

			tmp.command = help[1]
			tmp.keywords = "trade,prot,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "trade") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "prote"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "trader" and (chatvars.words[2] == "protect" or chatvars.words[2] == "unprotect" or chatvars.words[2] == "remove" or chatvars.words[2] == "add" or chatvars.words[2] == "del") then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			tmp.name = ""

			if chatvars.words[2] == "protect" or chatvars.words[2] == "unprotect" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "protect") + 8)
			else
				if chatvars.words[2] == "remove" then
					tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "remove") + 7)
				end
			end

			if chatvars.words[2] == "add" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "add ") + 4)
			end


			if chatvars.words[2] == "del" then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "del ") + 4)
			end

			if tmp.name == "" then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Name of previously marked out or saved area required. (not a location name)[-]")

				botman.faultyChat = false
				return true
			else
				tmp.name = string.trim(tmp.name)
			end

			prefabID = chatvars.playerid .. tmp.name

			if not prefabCopies[prefabID] then
				prefabID = LookupMarkedArea(tmp.name)
			end

			if not prefabCopies[prefabID] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked an area called " .. tmp.name .. ". Please do that first.[-]")
			else
				if chatvars.words[2] == "protect" or chatvars.words[2] == "add" then
					sendCommand("bm-safe add " .. prefabCopies[prefabID].x1 .. " " .. prefabCopies[prefabID].z1 .. " " .. prefabCopies[prefabID].x2 .. " " .. prefabCopies[prefabID].z2)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added trader protection on a marked area called " .. tmp.name .. ".[-]")
				else
					sendCommand("bm-safe del " .. prefabCopies[prefabID].x1 .. " " .. prefabCopies[prefabID].z1 .. " " .. prefabCopies[prefabID].x2 .. " " .. prefabCopies[prefabID].z2)
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed trader protection on a marked area called " .. tmp.name .. ".[-]")
				end

				igplayers[chatvars.playerid].undoPrefab = false
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_CancelMaze()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}stop/cancel maze"
			help[2] = "Aborts any maze(s) that you have told the bot to create."

			tmp.command = help[1]
			tmp.keywords = "maze,stop,canc,abor"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "stop" or chatvars.words[1] == "abort" or chatvars.words[1] == "cancel" and (chatvars.words[2] == "maze") then
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

			if botman.dbConnected then conn:execute("TRUNCATE miscQueue") end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Maze generation has been aborted.  You will need to clean up that mess yourself :)[-]")
			else
				irc_chat(chatvars.ircAlias, "Maze generation has been aborted.  You will need to clean up that mess yourself :)")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DeleteSave()
		local counter, cursor, errorString, row, owner

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}delete save {number taken from {#}list saves}"
			help[2] = "After {#}list saves, you can delete a save from the list.\n"
			help[2] = help[2] .. "Note that the list is temporary, but will last until the next time a list is generated.  If it doesn't work, do another {#}list saves."

			tmp.command = help[1]
			tmp.keywords = "del,list,save,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "list") or string.find(chatvars.command, "dele"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "delete" and chatvars.words[2] == "save" and chatvars.number ~= nil then
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

			cursor,errorString = conn:execute("SELECT * FROM list WHERE id = " .. chatvars.number)
			row = cursor:fetch({}, "a")

			if row then
				temp = string.split(row.thing, " ")
				conn:execute("DELETE FROM prefabCopies WHERE owner = '" .. escape(temp[1]) .. "' AND name = '" .. escape(temp[2]) .. "'")

				-- reload prefabCopies
				loadPrefabCopies()

				owner = temp[1]

				if players[temp[1]] then
					owner = players[temp[1]].name
				else
					if playersArchived[temp[1]] then
						owner = playersArchived[temp[1]].name
					end
				end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You have deleted the save called " .. temp[2] .. " created by " .. owner  .. ".[-]")
				else
					irc_chat(chatvars.ircAlias, "You have deleted the save called " .. temp[2] .. " created by " .. owner)
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_DigFill() -- diggy diggy hole
		local foundTall, foundLong, k, v, x1, y1, z1, x2, y2, z2

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}dig (or fill) {optional number} (default 5)"
			help[2] = "Dig a hole or fill a hole.\n"
			help[2] = help[2] .. "This can also be used to make tunnels and walls.\n"
			help[2] = help[2] .. "When not digging or filling up or down, a compass direction is needed (north, south, east, west)\n"
			help[2] = help[2] .. "There are several optional parts, wide, block, tall, base and long.\n"
			help[2] = help[2] .. "Default block is air, base is at your feet and the others default to 5.\n"
			help[2] = help[2] .. "Examples:\n"
			help[2] = help[2] .. " {#}dig north wide 3 tall 3 long 100\n"
			help[2] = help[2] .. " {#}dig bedrock wide 1\n"
			help[2] = help[2] .. " {#}dig up (makes a 5x5 room)\n"
			help[2] = help[2] .. " {#}dig up (or room) wide 5 tall 10 (makes a 10x10 room)\n"
			help[2] = help[2] .. " {#}dig up wide 50 tall 30 replace air block terrStone\n"
			help[2] = help[2] .. " {#}fill east base 70 wide 2 tall 10 long 50 block steelBlock\n"
			help[2] = help[2] .. " {#}fill bedrock wide 2 block stone\n"
			help[2] = help[2] .. " {#}fill {saved prefab} block stone\n"
			help[2] = help[2] .. ".\n"
			help[2] = help[2] .. "You can repeat the last command with /again and change direction with /again west\n"
			help[2] = help[2] .. "."

			tmp.command = help[1]
			tmp.keywords = "dig,fill,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "dig") or string.find(chatvars.command, "fill") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "dig" or chatvars.words[1] == "fill" then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.prefab = ""
			tmp.base = chatvars.intY
			tmp.tall = 5
			tmp.block = "air"
			tmp.direction = ""
			tmp.width = 5
			tmp.long = 5
			foundTall = false
			foundLong = false
			-- foundWally = false

			if prefabCopies[chatvars.playerid .. chatvars.words[2]] then
				tmp.prefab = chatvars.playerid .. chatvars.words[2]
			else
				for k,v in pairs(prefabCopies) do
					if v.name == chatvars.words[2] then
						tmp.prefab = k
					end
				end
			end

			if chatvars.words[1] == "fill" and chatvars.words[3] ~= "block" then
				tmp.block = chatvars.wordsOld[3]
				--tmp.block = getBlockName(tmp.block)
			end

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "wide" or chatvars.words[i] == "width"  then
					tmp.width = chatvars.words[i+1]
					tmp.width = math.abs(tmp.width)

					if not foundTall then
						-- default to same height
						tmp.tall = tmp.width
					end
				end

				if chatvars.words[i] == "prefab" then
					tmp.prefab = chatvars.playerid .. chatvars.wordsOld[i+1]
				end

				if chatvars.words[i] == "replace" then
					tmp.newblock = chatvars.wordsOld[i+1]
					--tmp.newblock = getBlockName(tmp.newblock)
				end

				if chatvars.words[i] == "block" then
					tmp.block = chatvars.wordsOld[i+1]
					--tmp.block = getBlockName(tmp.block)
				end

				if chatvars.words[i] == "tall" or chatvars.words[i] == "deep" or chatvars.words[i] == "height" or chatvars.words[i] == "hieght" then
					tmp.tall = chatvars.words[i+1]
					tmp.tall = math.abs(tmp.tall)
					foundTall = true
				end

				if chatvars.words[i] == "base" or chatvars.words[i] == "floor" or chatvars.words[i] == "bottom" then
					tmp.base = chatvars.words[i+1]
					tmp.base = math.abs(tmp.base)
				end

				if chatvars.words[i] == "long" or chatvars.words[i] == "length" then
					tmp.long = chatvars.words[i+1]
					tmp.long = math.abs(tmp.long)
					foundLong = true
				end

				if chatvars.words[i] == "up" or chatvars.words[i] == "room" then
					tmp.direction = "up"

					if not foundTall then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.tall = math.abs(tmp.number)
							foundTall = true
						end
					end
				end

				if chatvars.words[i] == "down" then
					tmp.direction = "down"

					if not foundTall then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.tall = math.abs(tmp.number)
							foundTall = true
						end
					end
				end

				if chatvars.words[i] == "north" then
					tmp.direction = "north"

					if not foundLong then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.long = math.abs(tmp.number)
							foundLong = true
						end
					end
				end

				if chatvars.words[i] == "south" then
					tmp.direction = "south"

					if not foundLong then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.long = math.abs(tmp.number)
							foundLong = true
						end
					end
				end

				if chatvars.words[i] == "east" then
					tmp.direction = "east"

					if not foundLong then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.long = math.abs(tmp.number)
							foundLong = true
						end
					end
				end

				if chatvars.words[i] == "west" then
					tmp.direction = "west"

					if not foundLong then
						tmp.number = tonumber(chatvars.words[i+1])

						if tmp.number ~= nil then
							tmp.long = math.abs(tmp.number)
							foundLong = true
						end
					end
				end

				if chatvars.words[i] == "bedrock" then
					tmp.direction = "bedrock"
				end
			end

			if not string.find(chatvars.command, "base") and not string.find(chatvars.command, "floor") and not string.find(chatvars.command, "bottom") then
				players[chatvars.playerid].lastChatLine = players[chatvars.playerid].lastChatLine .. " base " .. tmp.base
				players[chatvars.playerid].lastCommand = players[chatvars.playerid].lastCommand .. " base " .. tmp.base
			end

			-- subtract 1 so that walls 1 block wide etc are possible
			if tmp.direction == "" then
				if tmp.width > 0 then tmp.width = tmp.width - 1 end
				if tmp.long > 0 then tmp.long = tmp.long - 1 end
			end

			if tmp.prefab ~= "" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = prefabCopies[tmp.prefab].x1
				x2 = prefabCopies[tmp.prefab].x2
				y1 = prefabCopies[tmp.prefab].y1
				y2 = prefabCopies[tmp.prefab].y2
				z1 = prefabCopies[tmp.prefab].z1
				z2 = prefabCopies[tmp.prefab].z2

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end

				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " air " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. " 0")
					else
						sendCommand("bm-pblock air " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. " 0")
					end
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "bedrock" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX - tmp.width
				x2 = chatvars.intX + tmp.width
				y1 = 3
				y2 = chatvars.intY - 1
				z1 = chatvars.intZ - tmp.width
				z2 = chatvars.intZ + tmp.width

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "up" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX + tmp.width
				x2 = chatvars.intX - tmp.width
				y1 = chatvars.intY
				y2 = chatvars.intY + tmp.tall - 1
				z1 = chatvars.intZ - tmp.width
				z2 = chatvars.intZ + tmp.width

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "down" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX + tmp.width
				x2 = chatvars.intX - tmp.width
				y1 = chatvars.intY - 1
				y2 = chatvars.intY - tmp.tall
				z1 = chatvars.intZ - tmp.width
				z2 = chatvars.intZ + tmp.width

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "north" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX - tmp.width
				x2 = chatvars.intX + tmp.width
				y1 = tmp.base
				y2 = tmp.base + tmp.tall - 1
				z1 = chatvars.intZ + 1
				z2 = chatvars.intZ + tmp.long

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "south" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX - tmp.width
				x2 = chatvars.intX + tmp.width
				y1 = tmp.base
				y2 = tmp.base + tmp.tall - 1
				z1 = chatvars.intZ - 1
				z2 = chatvars.intZ - tmp.long

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "east" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX + 1
				x2 = chatvars.intX + tmp.long
				y1 = tmp.base
				y2 = tmp.base + tmp.tall - 1
				z1 = chatvars.intZ - tmp.width
				z2 = chatvars.intZ + tmp.width

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "west" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				x1 = chatvars.intX -1
				x2 = chatvars.intX - tmp.long
				y1 = tmp.base
				y2 = tmp.base + tmp.tall - 1
				z1 = chatvars.intZ - tmp.width
				z2 = chatvars.intZ + tmp.width

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bm-pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				else
					if tmp.newblock then
						sendCommand("bm-repblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					else
						sendCommand("bm-pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
					end
				end

				botman.faultyChat = false
				return true
			end

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Your " .. chatvars.words[1] .. " command failed or is wrong.[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_EraseArea()
		local x1, y1, z1, x2, y2, z2

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}erase {optional number} (default 5)\n"
			help[1] = help[1] .. " {#}erase block {block name} replace {with other block name} {optional number}\n"
			help[1] = help[1] .. "eg. {#}erase block stone replace air 20\n"
			help[2] = "Replace an area around you with air blocks.  Add a number to change the size."

			tmp.command = help[1]
			tmp.keywords = "erase,block,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "erase") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "erase" then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			tmp = {}

			if chatvars.number == nil then
				chatvars.number = 5
			end

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "block" then
					tmp.blockToErase = chatvars.wordsOld[i+1]
				end

				if chatvars.words[i] == "replace" then
					tmp.blockToReplace = chatvars.wordsOld[i+1]
				end
			end

			prefabCopies[chatvars.playerid .. "bottemp"] = {}
			prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
			prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
			x1 = chatvars.intX - chatvars.number
			x2 = chatvars.intX + chatvars.number
			y1 = chatvars.intY - chatvars.number
			y2 = chatvars.intY + chatvars.number
			z1 = chatvars.intZ - chatvars.number
			z2 = chatvars.intZ + chatvars.number

			-- normalise the coordinates from the south west corner to the north east corner
			x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

			prefabCopies[chatvars.playerid .. "bottemp"].x1 = x1
			prefabCopies[chatvars.playerid .. "bottemp"].x2 = x2
			prefabCopies[chatvars.playerid .. "bottemp"].y1 = y1
			prefabCopies[chatvars.playerid .. "bottemp"].y2 = y2
			prefabCopies[chatvars.playerid .. "bottemp"].z1 = z1
			prefabCopies[chatvars.playerid .. "bottemp"].z2 = z2

			--sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
			if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
			igplayers[chatvars.playerid].undoPrefab = false

			if tmp.blockToErase ~= nil then
				if tmp.blockToReplace == nil then
					sendCommand("bm-repblock " .. tmp.blockToErase .. " air "  .. x1 .. " " .. x2 .. " " .. y1 .. " " .. y2 .. " " .. z1 .. " " .. z2 .. " 0")
				else
					sendCommand("bm-repblock " .. tmp.blockToErase .. " " .. tmp.blockToReplace .. " "  .. x1 .. " " .. x2 .. " " .. y1 .. " " .. y2 .. " " .. z1 .. " " .. z2 .. " 0")
				end
			else
				sendCommand("bm-pblock air " .. x1 .. " " .. x2 .. " " .. y1 .. " " .. y2 .. " " .. z1 .. " " .. z2 .. " 0")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListItems()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list (or {#}li) {partial name of an item or block}"
			help[2] = "List all items containing the text you are searching for."

			tmp.command = help[1]
			tmp.keywords = "list,item,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "list" or chatvars.words[1] == "li") and chatvars.words[2] ~= "saves" and chatvars.words[2] ~= nil and chatvars.words[3] == nil then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			playerListItems = chatvars.playerid
			sendCommand("li " .. chatvars.words[2])
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListSaves()
		local name, counter, cursor, errorString, row

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list saves {optional player name}"
			help[2] = "List all your saved marked areas or those of someone else.  This list is coordinate pairs of places in the world that you have marked for some block command.\n"
			help[2] = help[2] .. "You can use a named save with the block commands.\n"
			help[2] = help[2] .. "You can teleport to them with {#}tp #{name of marked area}.\n"
			help[2] = help[2] .. "You can delete one {#}delete save {list number of marked area}."

			tmp.command = help[1]
			tmp.keywords = "list,save,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "list" and chatvars.words[2] == "saves" then
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

			counter = 1
			tmp.pid = 0

			if chatvars.words[3] ~= nil then
				tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "saves") + 7)
				tmp.name = string.trim(tmp.name)
				tmp.pid = LookupPlayer(tmp.name)

				if tmp.pid == 0 then
					tmp.pid = LookupArchivedPlayer(tmp.name)

					if tmp.pid ~= 0 then
						tmp.name = playersArchived[tmp.pid].name
					end
				else
					tmp.name = players[tmp.pid].name
				end
			end

			if botman.dbConnected then
				conn:execute("TRUNCATE list")

				if tmp.pid ~= 0 then
					cursor,errorString = conn:execute("SELECT * FROM prefabCopies WHERE owner = " .. tmp.pid .. " ORDER BY name")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Marked areas created by " .. tmp.name .. ":[-]")
					else
						irc_chat(chatvars.ircAlias, "Marked areas created by " .. tmp.name)
					end
				else
					cursor,errorString = conn:execute("SELECT * FROM prefabCopies ORDER BY name")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Marked areas:[-]")
					else
						irc_chat(chatvars.ircAlias, "Marked areas:")
					end

				end

				row = cursor:fetch({}, "a")

				if not row then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]None recorded.[-]")
					else
						irc_chat(chatvars.ircAlias, "None recorded.")
					end
				end

				while row do
					if players[row.owner] then
						name = players[row.owner].name
					else
						name = row.owner
					end

					if playersArchived[row.owner] then
						name = playersArchived[row.owner].name
					end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]#" .. counter .. " " .. name .. ": " .. row.name .. "  P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "   P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2 .. "[-]")
					else
						irc_chat(chatvars.ircAlias, "#" .. counter .. " " .. name .. ": " .. row.name .. "  P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "  P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2)
					end

					conn:execute("INSERT INTO list (id, thing, class, steam) VALUES (" .. counter .. ",'" .. escape(row.owner .. " " .. row.name) .. "','" .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "'," .. chatvars.playerid .. ")")
					counter = counter + 1
					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LoadPrefab()
		local i

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}load prefab {name}\n"
			help[1] = help[1] .. " {#}load prefab {name} at {x} {y} {z} face {0-3}\n"
			help[1] = help[1] .. " {#}load prefab {name} here\n"
			help[1] = help[1] .. "Everything after the prefab name is optional and if not given, the stored coords and rotation will be used."
			help[2] = "Restore a saved prefab in place or place it somewhere else.\n"
			help[2] = help[2] .. "If you provide coords and an optional rotation (default is 0 - north), you will make a new copy of the prefab at those coords.\n"
			help[2] = help[2] .. "If you instead add here, it will load on your current position with optional rotation.\n"
			help[2] = help[2] .. "If you only provide the name of the saved prefab, it will restore the prefab in place which replaces the original with the copy."

			tmp.command = help[1]
			tmp.keywords = "load,prefab,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "load") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "paste"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "load" and chatvars.words[2] == "prefab" then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			if (chatvars.words[3] == nil) then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "load prefab {name} at {x} {y} {z} face {0-3}[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Everything after the prefab name is optional and if not given, the stored coords and rotation will be used.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]add coords and optional rotation to copy of the prefab or type here to place it at your feet.[-]")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]To restore the prefab in place, just give the prefab name. Stock prefabs will always spawn at your feet if no coord is given.[-]")
				botman.faultyChat = false
				return true
			end

			tmp.prefab = chatvars.words[3]
			tmp.face = 0
			tmp.coords = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ

			prefabID = chatvars.playerid .. tmp.prefab

			if not prefabCopies[prefabID] then
				prefabID = LookupMarkedArea(tmp.prefab)
			end

			if (prefabCopies[prefabID]) and not (string.find(chatvars.command, " at ")) then
				if tonumber(prefabCopies[prefabID].y1) < tonumber(prefabCopies[prefabID].y2) then
					tmp.coords = prefabCopies[prefabID].x1 .. " " .. prefabCopies[prefabID].y1 .. " " .. prefabCopies[prefabID].z1
				else
					tmp.coords = prefabCopies[prefabID].x2 .. " " .. prefabCopies[prefabID].y2 .. " " .. prefabCopies[prefabID].z2
				end
			end

			if (string.find(chatvars.command, " face ")) then
				tmp.face = string.sub(chatvars.command, string.find(chatvars.command, " face ") + 6, string.len(chatvars.command))

				if (string.find(chatvars.command, " at ")) then
					tmp.coords = string.sub(chatvars.command, string.find(chatvars.command, " at ") + 4, string.find(chatvars.command, " face") - 1)
				end
			else
				if (string.find(chatvars.command, " at ")) then
					tmp.coords = string.sub(chatvars.command, string.find(chatvars.command, " at ") + 4, string.len(chatvars.command))
				end
			end

			if chatvars.words[4] == "here" then
				tmp.coords = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
			end

			sendCommand("bm-prender " .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A prefab called " .. chatvars.wordsOld[3] .. " should have spawned.  If it didn't either the prefab isn't called " .. tmp.prefab .. " or it doesn't exist.[-]")
			igplayers[chatvars.playerid].undoPrefab = true
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MakeMaze()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}make maze (default maze 20 x 20)\n"
			help[1] = help[1] .. " {#}make maze wall {block name} fill {air block} width {number} length {number} height {number} x {x coord} y {y coord} z {z coord}\n"
			help[1] = help[1] .. "The bot also accepts wide, long, and tall instead of width, length, and height.\n"
			help[1] = help[1] .. "The maze will generate with no roof.  If you want a roof add the word roof.\n"
			help[1] = help[1] .. "If you want a multi-level maze add levels {number}. Note: it will include a floor.\n"
			help[1] = help[1] .. "You will need to cut holes or make rooms yourself."
			help[2] = "Generate and build a random maze.  Someone must stay there until the maze completes or it will fail to spawn fully.\n"
			help[2] = help[2] .. "Default values: wall steelBlock fill air width 20 length 20 height 3. It uses your current position for x, y and z if not given.\n"
			help[2] = help[2] .. "Note: width and length are multiplied by 2."

			tmp.command = help[1]
			tmp.keywords = "make,maze,rand"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "make" and chatvars.words[2] == "maze" then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			tmp = {}
			tmp.wallBlock = "steelBlock"
			tmp.fillBlock = "air"
			tmp.x = chatvars.intX
			tmp.y = chatvars.intY
			tmp.z = chatvars.intZ
			tmp.width = 20
			tmp.length = 20
			tmp.height = 3
			tmp.levels = 1
			tmp.roof = false

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "roof" then
					tmp.roof = true
				end

				if chatvars.words[i] == "levels" then
					tmp.levels = math.abs(chatvars.words[i+1])

					if tmp.levels == 0 then
						tmp.levels = 1
					end
				end

				if chatvars.words[i] == "wall" then
					tmp.wallBlock = chatvars.words[i+1]
				end

				if chatvars.words[i] == "fill" then
					tmp.fillBlock = chatvars.words[i+1]
				end

				if chatvars.words[i] == "x" then
					tmp.x = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "y" then
					tmp.y = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "z" then
					tmp.z = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "width" or chatvars.words[i] == "wide" then
					tmp.width = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "length" or chatvars.words[i] == "long" then
					tmp.length = tonumber(chatvars.words[i+1])
				end

				if chatvars.words[i] == "height" or chatvars.words[i] == "tall" then
					tmp.height = tonumber(chatvars.words[i+1])
				end
			end

			igplayers[chatvars.playerid].undoPrefab = false
			renderMaze(tmp.wallBlock, tmp.x, tmp.y, tmp.z, tmp.width, tmp.length, tmp.height, tmp.fillBlock, tmp.roof, tmp.levels)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset player profile {player name}"
			help[2] = "Make the server delete a player's profile."

			tmp.command = help[1]
			tmp.keywords = "reset,play,profile"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "play"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and chatvars.words[2] == "player" and chatvars.words[3] == "profile" and chatvars.words[4] ~= nil then
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
			pname = string.sub(chatvars.command, string.find(chatvars.command, " profile ") + 10)

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

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Are you sure you want to reset the player profile of " .. players[id].name .. "?  Answer yes to proceed or anything else to cancel.[-]")
			else
				irc_chat(chatvars.ircAlias, "Are you sure you want to reset the player profile of " .. players[id].name .. "?  Answer yes to proceed or anything else to cancel.")
			end

			players[chatvars.playerid].botQuestion = "reset profile"
			players[chatvars.playerid].botQuestionID = id

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetPrefab()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset prefab {player name}"
			help[2] = "Reset a prefab where the player is standing.  If doing on yourself in-game you only need {#}reset prefab."

			tmp.command = help[1]
			tmp.keywords = "reset,prefab,poi"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "reset") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "poi"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and chatvars.words[2] == "prefab" then
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

			if chatvars.words[3] ~= nil then
				pname = nil
				pname = string.sub(chatvars.command, string.find(chatvars.command, " prefab ") + 9)
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
			else
				id = chatvars.playerid

				if (chatvars.playername == "Server") then
					irc_chat(chatvars.ircAlias, "You must be in-game if you do not specify a player for this command.")

					botman.faultyChat = false
					return true
				end
			end

			sendCommand("bm-resetprefab " .. id)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]A prefab at " .. players[id].name .. "'s position should be reset now.[-]")
			else
				irc_chat(chatvars.ircAlias, "A prefab at " .. players[id].name .. "'s position should be reset now.")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ResetRegionsNow()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset regions now"
			help[2] = "Reboot the server and reset all reset regions immediately. (result varies subject to other settings)"

			tmp.command = help[1]
			tmp.keywords = "reset,now"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "now") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "region")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "reset" and chatvars.words[2] == "regions" and chatvars.words[3] == "now" then
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

			sendCommand("bm-resetregions enable")
			sendCommand("bm-resetregions now")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SavePrefab()
		local x1, y1, z1, x2, y2, z2

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}save {name}"
			help[2] = "After marking out the area you want to copy, you can save it."

			tmp.command = help[1]
			tmp.keywords = "save,prefab,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "save" and chatvars.words[2] ~= nil then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			if not prefabCopies[chatvars.playerid .. chatvars.words[2]] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked a prefab called " .. chatvars.words[2] .. ". Please do that first.[-]")
			else
				x1 = prefabCopies[chatvars.playerid .. chatvars.words[2]].x1
				x2 = prefabCopies[chatvars.playerid .. chatvars.words[2]].x2
				y1 = prefabCopies[chatvars.playerid .. chatvars.words[2]].y1
				y2 = prefabCopies[chatvars.playerid .. chatvars.words[2]].y2
				z1 = prefabCopies[chatvars.playerid .. chatvars.words[2]].z1
				z2 = prefabCopies[chatvars.playerid .. chatvars.words[2]].z2

				-- normalise the coordinates from the south west corner to the north east corner
				x1, y1, z1, x2, y2, z2 = getSWNECoords(x1, y1, z1, x2, y2, z2)

				prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = x1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = x2
				prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = y1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = y2
				prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = z1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = z2

				sendCommand("exportprefab " .. chatvars.words[2] .. " " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You saved a prefab called " .. chatvars.wordsOld[2] .. ".[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetChatColours()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set new player/player/donor/prisoner/mod/admin/owner chat colour FFFFFF\n"
			help[1] = help[1] .. " {#}reset chat colour"
			help[2] = "Set the default chat colour for a class of player.  You can also set chat colour for a named player.\n"
			help[2] = help[2] .. "eg. {#}set player joe chat colour B0E0E6\n"
			help[2] = help[2] .. "To disable automatic chat colouring, set it to white which is FFFFFF\n"
			help[2] = help[2] .. "To reset everyone to white type {#}reset chat colour everyone"

			tmp.command = help[1]
			tmp.keywords = "set,clear,chat,colo"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "reset") and string.find(chatvars.command, "chat col") then
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
			tmp.target = chatvars.words[2]
			tmp.namedPlayer = false

			if string.find(chatvars.command, "reset chat colo") and chatvars.words[4] ~= nil then
				if chatvars.words[4] == "everyone" or chatvars.words[4] == "all" then
					for k,v in pairs(players) do
						v.chatColour = "FFFFFF"
					end

					for k,v in pairs(playersArchived) do
						v.chatColour = "FFFFFF"
					end

					for k,v in pairs(igplayers) do
						setPlayerColour(k, "FFFFFF")
					end

					if botman.dbConnected then conn:execute("UPDATE players SET chatColour = 'FFFFFF'") end
					if botman.dbConnected then conn:execute("UPDATE playersArchived SET chatColour = 'FFFFFF'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Everyone's stored chat colour is white, but players will still be coloured if any player classes are coloured (eg. donors).[-]")
					else
						irc_chat(chatvars.ircAlias, "Everyone's stored chat colour is white, but players will still be coloured if any player classes are coloured (eg. donors).")
					end
				else
					tmp.name = chatvars.words[4]
					tmp.pid = LookupPlayer(tmp.name)

					if tmp.pid == 0 then
						tmp.pid = LookupArchivedPlayer(tmp.name)

						if tmp.pid ~= 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. tmp.name)
							end
						end

						botman.faultyChat = false
						return true
					else
						tmp.name = players[tmp.pid].name
					end

					if tmp.pid ~= 0 then
						setPlayerColour(tmp.pid, "FFFFFF")
						players[tmp.pid].chatColour = tmp.colour
						if botman.dbConnected then conn:execute("UPDATE players SET chatColour = 'FFFFFF' WHERE steam = " .. tmp.pid) end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.name ..  "'s name is now coloured coloured [FFFFFF]white[-][-]")
						else
							irc_chat(chatvars.ircAlias, tmp.name ..  "'s name is now coloured white")
						end

						botman.faultyChat = false
						return true
					end
				end

				botman.faultyChat = false
				return true
			end

			for i=4,chatvars.wordCount,1 do
				if chatvars.words[i] == "colour" or chatvars.words[i] == "color" then
					tmp.colour = chatvars.words[i+1]
				end
			end

			-- special case setting chat colour for a named player
			if chatvars.words[2] == "player" and chatvars.words[3] ~= "chat" then
				tmp.namedPlayer = true
			end

			if tmp.target ~= "new" and tmp.target ~= "player" and tmp.target ~= "donor" and tmp.target ~= "prisoner" and tmp.target ~= "mod" and tmp.target ~= "admin" and tmp.target ~= "owner" and not tmp.namedPlayer then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.[-]")
				else
					irc_chat(chatvars.ircAlias, "Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.")
				end

				botman.faultyChat = false
				return true
			end

			if tmp.colour == nil then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]6 character hex colour code required eg. FFFFFF for white.[-]")
				else
					irc_chat(chatvars.ircAlias, "6 character hex colour code required eg. FFFFFF for white.")
				end

				botman.faultyChat = false
				return true
			end

			-- strip out any # characters
			tmp.colour = tmp.colour:gsub("#", "")
			tmp.colour = string.upper(string.sub(tmp.colour, 1, 6))

			if tmp.target == "new" then
				server.chatColourNewPlayer = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourNewPlayer = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New player names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "New player names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 99 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "player" then
				if tmp.namedPlayer then
					tmp.name = string.sub(chatvars.command, string.find(chatvars.command, " player ") + 8, string.find(chatvars.command, " chat ") - 1)
					tmp.pid = LookupPlayer(tmp.name)

					if tmp.pid == 0 then
						tmp.pid = LookupArchivedPlayer(tmp.name)

						if tmp.pid ~= 0 then
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.[-]")
							else
								irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server, then repeat this command.")
							end
						else
							if (chatvars.playername ~= "Server") then
								message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found called " .. tmp.name .. "[-]")
							else
								irc_chat(chatvars.ircAlias, "No player found called " .. tmp.name)
							end
						end

						botman.faultyChat = false
						return true
					else
						tmp.name = players[tmp.pid].name
					end

					if tmp.pid ~= 0 then
						setPlayerColour(tmp.pid, tmp.colour)
						players[tmp.pid].chatColour = tmp.colour
						if botman.dbConnected then conn:execute("UPDATE players SET chatColour = '" .. escape(tmp.colour) .. "' WHERE steam = " .. tmp.pid) end

						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. tmp.name ..  "'s name is now coloured coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-][-]")
						else
							irc_chat(chatvars.ircAlias, tmp.name ..  "'s name is now coloured " .. tmp.colour)
						end

						botman.faultyChat = false
						return true
					end
				else
					server.chatColourPlayer = tmp.colour
					if botman.dbConnected then conn:execute("UPDATE server SET chatColourPlayer = '" .. escape(tmp.colour) .. "'") end

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Non-new player names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
					else
						irc_chat(chatvars.ircAlias, "Non-new player names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
					end

					for k,v in pairs(igplayers) do
						if accessLevel(k) == 90 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
							setPlayerColour(k, tmp.colour)
						end
					end
				end
			end

			if tmp.target == "donor" then
				server.chatColourDonor = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourDonor = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donor's names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Donor's names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if isDonor(k) and string.sub(v.chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "prisoner" then
				server.chatColourPrisoner = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourPrisoner = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Prisoner's names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-][-]")
				else
					irc_chat(chatvars.ircAlias, "Prisoner's names will be coloured " .. tmp.colour)
				end

				for k,v in pairs(igplayers) do
					if players[k].prisoner then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "mod" then
				server.chatColourMod = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourMod = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Mod names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Mod names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 2 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "admin" then
				server.chatColourAdmin = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourAdmin = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admin names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Admin names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 1 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			if tmp.target == "owner" then
				server.chatColourOwner = tmp.colour
				if botman.dbConnected then conn:execute("UPDATE server SET chatColourOwner = '" .. escape(tmp.colour) .. "'") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner names will be coloured [" .. tmp.colour .. "]" .. tmp.colour .. "[-] if they haven't been assigned a colour of their own.[-]")
				else
					irc_chat(chatvars.ircAlias, "Owner names will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
				end

				for k,v in pairs(igplayers) do
					if accessLevel(k) == 0 and string.sub(players[k].chatColour, 1, 6) == "FFFFFF" then
						setPlayerColour(k, tmp.colour)
					end
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetClearHorde()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set/clear horde"
			help[2] = "Marks your current position to spawn a horde there with {#}spawn horde.\n"
			help[2] = help[2] .. "Clear horde doesn't remove the horde. It only clears the saved coordinate."

			tmp.command = help[1]
			tmp.keywords = "set,clear,horde"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "set" or chatvars.words[1] == "clear") and chatvars.words[2] == "horde" then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			if chatvars.words[1] == "set" then
				-- mark the player's current position for spawning a horde with /spawn horde
				igplayers[chatvars.playerid].horde = chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Type " .. server.commandPrefix .. "spawn horde, to make a horde spawn around this spot.[-]")
			else
				-- forget the pre-recorded coords of the horde spawn point
				igplayers[chatvars.playerid].horde = nil
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You have unmarked the horde.  Typing " .. server.commandPrefix .. "spawn horde will focus the horde on you if you don't target a player or location.[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleAnticheat()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable anticheat"
			help[2] = "Enable or disable the anticheat feature in the Botman mod.  Default is disabled."

			tmp.command = help[1]
			tmp.keywords = "able,cheat"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "able") or string.find(chatvars.command, "cheat")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "able") and chatvars.words[2] == "anticheat" then
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
				modBotman.anticheat = true
				conn:execute("UPDATE modBotman set anticheat = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The anticheat feature of the Botman mod is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The anticheat feature of the Botman mod is enabled.")
				end

				sendCommand("bm-anticheat enable")
			else
				modBotman.anticheat = false
				conn:execute("UPDATE modBotman set anticheat = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The anticheat feature of the Botman mod is turned off.[-]")
				else
					irc_chat(chatvars.ircAlias, "The anticheat feature of the Botman mod is turned off.")
				end

				sendCommand("bm-anticheat disable")
			end

			botman.faultyChat = false
			return true
		end
	end


-- ###################  clan commands ################


	local function cmd_SetMaxClans()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max clans {number of clans}"
			help[2] = "Set the maximum number of clans."

			tmp.command = help[1]
			tmp.keywords = "set,max,clan"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "clan")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "clans" then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required.")
				end

				botman.faultyChat = false
				return true
			end

			modBotman.clanMaxClans = math.abs(chatvars.number)
			conn:execute("UPDATE modBotman set clanMaxClans = " .. math.abs(chatvars.number))

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A maximum of " .. modBotman.clanMaxClans .. " clans can be created.[-]")
			else
				irc_chat(chatvars.ircAlias, "A maximum of " .. modBotman.clanMaxClans .. " clans can be created.")
			end

			sendCommand("bm-clan max clans " .. modBotman.clanMaxClans)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMaxClanPlayers()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set max clan players {number of players}"
			help[2] = "Set the maximum number of players clans can have."

			tmp.command = help[1]
			tmp.keywords = "set,max,clan"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "botman") or string.find(chatvars.command, "clan"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "max" and chatvars.words[3] == "clan" and chatvars.words[4] == "players" then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required.")
				end

				botman.faultyChat = false
				return true
			end

			modBotman.clanMaxPlayers = math.abs(chatvars.number)
			conn:execute("UPDATE modBotman set clanMaxPlayers = " .. modBotman.clanMaxPlayers)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Clans can have a maximum of " .. modBotman.clanMaxPlayers .. " players.[-]")
			else
				irc_chat(chatvars.ircAlias, "Clans can have a maximum of " .. modBotman.clanMaxPlayers .. " players.")
			end

			sendCommand("bm-clan max players " .. modBotman.clanMaxPlayers)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMinClanLevel()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set min clan level {player level}"
			help[2] = "Set the minimum player level required to join a clan."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,min,clan"
				tmp.accessLevel = 0
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "clan")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "min" and chatvars.words[3] == "clan" and chatvars.words[4] == "level" then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required.")
				end

				botman.faultyChat = false
				return true
			end

			modBotman.clanMinLevel = math.abs(chatvars.number)
			conn:execute("UPDATE modBotman set clanMinLevel = " .. modBotman.clanMinLevel)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Players must have a minimum player level of " .. modBotman.clanMinLevel .. " to join clans.[-]")
			else
				irc_chat(chatvars.ircAlias, "Players must have a minimum player level of " .. modBotman.clanMinLevel .. " to join clans.")
			end

			sendCommand("bm-clan min_level " .. modBotman.clanMinLevel)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleClans()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable clans"
			help[2] = "Enable or disable the clan feature in the Botman mod.  Default is disabled."

			tmp.command = help[1]
			tmp.keywords = "able,clan"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "able") or string.find(chatvars.command, "clan")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "able") and chatvars.words[2] == "clans" then
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
				modBotman.clanEnabled = true
				conn:execute("UPDATE modBotman set clanEnabled = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The clan feature of the Botman mod is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The clan feature of the Botman mod is enabled.")
				end

				sendCommand("bm-clan enable")
			else
				modBotman.clanEnabled = false
				conn:execute("UPDATE modBotman set clanEnabled = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The clan feature of the Botman mod is turned off.[-]")
				else
					irc_chat(chatvars.ircAlias, "The clan feature of the Botman mod is turned off.")
				end

				sendCommand("bm-clan disable")
			end

			botman.faultyChat = false
			return true
		end
	end


-- ###################  reset region commands ################


	local function cmd_SetResetDelay()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set reset delay {days}"
			help[2] = "Sets the delay of days between resets. 0 for every reboot."

			tmp.command = help[1]
			tmp.keywords = "set,reset,delay,day"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "reset")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "reset" and chatvars.words[3] == "delay" and chatvars.words[4] ~= nil then
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
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Number required.[-]")
				else
					irc_chat(chatvars.ircAlias, "Number required.")
				end

				botman.faultyChat = false
				return true
			end

			chatvars.number = math.abs(chatvars.number) -- don't be so negative
			modBotman.resetsDelay = math.abs(chatvars.number)
			conn:execute("UPDATE modBotman set resetsDelay = " .. modBotman.resetsDelay)

			if modBotman.resetsDelay > 0 then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will be reset every " .. modBotman.resetsDelay .. " days.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will be reset every " .. modBotman.resetsDelay .. " days.")
				end
			else
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will be reset every reboot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will be reset every reboot.")
				end
			end

			sendCommand("bm-resetregions delay " .. modBotman.resetsDelay)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SetMapColour()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}set map colour FF0000 (red is the default colour)"
			help[2] = "Set the colour of reset regions on Alloc's web map."

			tmp.command = help[1]
			tmp.keywords = "set,map,colo"
			tmp.accessLevel = 1
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "map") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "set" and chatvars.words[2] == "map" and string.find(chatvars.words[3], "colo") and chatvars.words[4] then
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

			if string.sub(chatvars.words[4], 1, 1) == "#" then
				chatvars.words[4] = string.sub(chatvars.words[4], 2)
			end

			if not isHexCode(chatvars.words[4]) then
				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Please use the full 6 character colour code. I am just a simple bot.[-]")
				else
					irc_chat(chatvars.ircAlias, "Please use the full 6 character colour code. I am just a simple bot.")
				end

				botman.faultyChat = false
				return true
			end

			modBotman.webmapColour = string.upper(chatvars.words[4])
			if botman.dbConnected then conn:execute("UPDATE modBotman SET webmapColour = '" .. escape(modBotman.webmapColour) .. "'") end

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions in Alloc's webmap will be coloured using the [-][" .. modBotman.webmapColour .. "]" .. modBotman.webmapColour .. " bbcolor code.[-]")
			else
				irc_chat(chatvars.ircAlias, "Reset regions in Alloc's webmap will be coloured using the " .. modBotman.webmapColour .. " bbcolor code.")
			end

			sendCommand("bm-webmapzones color " .. modBotman.webmapColour)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleMapping()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable mapping"
			help[2] = "Enable or disable plotting reset regions on Alloc's web map."

			tmp.command = help[1]
			tmp.keywords = "able,map,reset"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "able") or string.find(chatvars.command, "map") or string.find(chatvars.command, "reset")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "able") and chatvars.words[2] == "mapping" then
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
				modBotman.webmapEnabled = true
				conn:execute("UPDATE modBotman set webmapEnabled = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Alloc's web map will be altered by the Botman mod (requires 0harmony.dll in 7DayToDieServer_Data/Managed).[-]")
				else
					irc_chat(chatvars.ircAlias, "Alloc's web map will be altered by the Botman mod (requires 0harmony.dll in 7DayToDieServer_Data/Managed).")
				end

				sendCommand("bm-webmapzones enable")
			else
				modBotman.webmapEnabled = false
				conn:execute("UPDATE modBotman set webmapEnabled = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Alloc's web map will not be altered by the Botman mod.[-]")
				else
					irc_chat(chatvars.ircAlias, "Alloc's web map will not be altered by the Botman mod.")
				end

				sendCommand("bm-webmapzones disable")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleResetRegions()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable reset regions"
			help[2] = "Enable or disable the Botman mod's reset regions feature.  Default is disabled.\n"
			help[2] = help[2] .. "This is very similar to the bot's reset zones except that they are limited to whole regions and can actually reset the region or just prefabs or just remove claims."

			tmp.command = help[1]
			tmp.keywords = "able,reset"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "able") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "region")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "able") and chatvars.words[2] == "reset" and chatvars.words[3] == "regions" then
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
				modBotman.resetsEnabled = true
				conn:execute("UPDATE modBotman set resetsEnabled = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The reset regions feature of the Botman mod is enabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The reset regions feature of the Botman mod is enabled.")
				end

				sendCommand("bm-resetregions enable")
			else
				modBotman.resetsEnabled = false
				conn:execute("UPDATE modBotman set resetsEnabled = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The reset regions feature of the Botman mod is disabled.[-]")
				else
					irc_chat(chatvars.ircAlias, "The reset regions feature of the Botman mod is disabled.")
				end

				sendCommand("bm-resetregions disable")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleResetRegionsClaims()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}reset regions remove/leave claims (default is leave claims)"
			help[2] = "Reset regions can remove or leave claim blocks."

			tmp.command = help[1]
			tmp.keywords = "claim,lcb,reset,region"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "claim") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "region") or string.find(chatvars.command, "lcb")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if string.find(chatvars.words[1], "reset") and chatvars.words[2] == "regions" and (chatvars.words[3] == "remove" or chatvars.words[3] == "leave") and chatvars.words[4] == "claims" then
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

			if chatvars.words[3] == "remove" then
				modBotman.resetsRemoveLCB = true
				conn:execute("UPDATE modBotman set resetsRemoveLCB = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will remove claim blocks.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will remove claim blocks.")
				end

				sendCommand("bm-resetregions removelcbs true")
			else
				modBotman.resetsRemoveLCB = false
				conn:execute("UPDATE modBotman set resetsRemoveLCB = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will leave claim blocks unless the entire region is reset.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will leave claim blocks unless the entire region is reset.")
				end

				sendCommand("bm-resetregions removelcbs false")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleResetRegionsPrefabs()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}enable/disable reset prefabs"
			help[2] = "The Botman mod can reset entire regions (the default) or just the prefabs they contain."

			tmp.command = help[1]
			tmp.keywords = "reset,region,prefab"
			tmp.accessLevel = 0
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "prefab") or string.find(chatvars.command, "reset") or string.find(chatvars.command, "region")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (string.find(chatvars.words[1], "enable") or string.find(chatvars.words[1], "disable")) and chatvars.words[2] == "reset" and string.find(chatvars.words[3], "prefab") then
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
				modBotman.resetsPrefabsOnly = true
				conn:execute("UPDATE modBotman set resetsPrefabsOnly = 1")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will only reset prefabs.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will only reset prefabs.")
				end

				sendCommand("bm-resetregions prefabsonly true")
			else
				modBotman.resetsPrefabsOnly = false
				conn:execute("UPDATE modBotman set resetsPrefabsOnly = 0")

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Reset regions will reset whole regions.[-]")
				else
					irc_chat(chatvars.ircAlias, "Reset regions will reset whole regions.")
				end

				sendCommand("bm-resetregions prefabsonly false")
			end

			botman.faultyChat = false
			return true
		end
	end

-- ###################  zombie announcer commands ################



-- ####################################################################################


	local function cmd_SpawnHorde()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}spawn horde {optional player or location name} {number of zombies}"
			help[2] = "Spawn a horde around a player or location or at a marked coordinate.  See {#}set horde."

			tmp.command = help[1]
			tmp.keywords = "spawn,horde"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "spawn" and (chatvars.words[2] == "horde") then
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

			if chatvars.words[3] ~= nil then
				tmp.id = LookupPlayer(chatvars.words[3])

				if chatvars.number then
					tmp.number = math.abs(chatvars.number)
				else
					tmp.number = 5
				end

				if tmp.id == 0 then
					tmp.id = LookupArchivedPlayer(chatvars.words[3])

					if not (tmp.id == 0) then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
						else
							irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.id].name .. " was archived. Get them to rejoin the server and repeat this command.")
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]No player found matching " .. chatvars.words[3] .. "[-]")
						else
							irc_chat(chatvars.ircAlias, "No player found matching " .. chatvars.words[3])
						end
					end

					botman.faultyChat = false
					return true
				else
					if not igplayers[tmp.id] then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " isn't playing right now.[-]")
						else
							irc_chat(chatvars.ircAlias, players[tmp.id].name .. " isn't playing right now.")
						end

						botman.faultyChat = false
						return true
					end
				end

				if tmp.id ~= 0 then
					if igplayers[tmp.id] then
						sendCommand("bm-spawnhorde " .. tmp.id .. " " .. tmp.number)
						irc_chat(server.ircMain, "Horde spawned by bot at " .. igplayers[tmp.id].name .. "'s position at " .. igplayers[tmp.id].xPos .. " " .. igplayers[tmp.id].yPos .. " " .. igplayers[tmp.id].zPos)
					end
				else
					tmp.loc = LookupLocation(chatvars.words[3])

					if tmp.loc ~= nil then
						sendCommand("bm-spawnhorde " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z .. " " .. tmp.number)
						irc_chat(server.ircMain, "Horde spawned by bot at " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z)
					end
				end
			else
				-- spawn horde on self
				if (chatvars.playername ~= "Server") then
					sendCommand("bm-spawnhorde " .. chatvars.playerid .. " " .. tmp.number)
				else
					irc_chat(chatvars.ircAlias, "You need to be on the server or specify a player that isn't you, or a location.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleMutePlayer()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}mute/unmute {player name}"
			help[2] = "Muting a player blocks their ingame chat from being seen by other players.  You will still see it from the web client.\n"
			help[2] = help[2] .. "It does not block voice chat sadly."

			tmp.command = help[1]
			tmp.keywords = "mute,play"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "mute")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "mute" or chatvars.words[1] == "unmute") and chatvars.words[2] ~= nil then
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

			tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "mute ") + 5)
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

			if chatvars.words[1] == "unmute" then
				unmutePlayer(tmp.id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.id].name .. " can chat again D:[-]")
				end
			else
				mutePlayer(tmp.id)

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Chat from player " .. players[tmp.id].name .. " is blocked :D[-]")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ToggleShowHideCommands()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}show/hide commands"
			help[2] = "Hide commands from ingame chat which makes them all PM's or show them which makes them public.  They will still appear in the web client."

			tmp.command = help[1]
			tmp.keywords = "show,hide,comm"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "botman") or string.find(chatvars.command, "comm")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if (chatvars.words[1] == "hide" or chatvars.words[1] == "show") and chatvars.words[2] == "commands" and chatvars.words[3] == nil  then
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

			if chatvars.words[1] == "hide" then
				hidePlayerChat(server.commandPrefix)
				if botman.dbConnected then conn:execute("UPDATE server SET hideCommands = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now hidden from global chat.[-]")
				else
					irc_chat(server.ircMain, "Bot commands are now hidden from global chat.")
				end
			else
				hidePlayerChat()
				if botman.dbConnected then conn:execute("UPDATE server SET hideCommands = 0") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now visible in global chat.[-]")
				else
					irc_chat(server.ircMain, "Bot commands are now visible in global chat.")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_Undo()
		local restoreName

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}undo"
			help[2] = "The block commands bm-prender, bm-pdup and bm-repblock allow for the last command to be undone, however since more than one person can command the bot to do block commands\n"
			help[2] = help[2] .. "it is possible that other block commands have been done by the bot since your last block command.  If the last block command came from you, the bot will undo it."

			tmp.command = help[1]
			tmp.keywords = "undo,save,botman"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "undo") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "botman") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "undo" and (chatvars.words[2] == nil or chatvars.words[2] == "save") then
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

				irc_chat(chatvars.ircAlias, "You can only use this command ingame.")
				botman.faultyChat = false
				return true
			end

			--if chatvars.words[2] == "save" then
				--sendCommand(prender .. " " .. chatvars.playerid .. "bottemp" .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1  .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1)
			--else
				sendCommand("bm-undo")
			--end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Block undo command (bm-undo) sent. If it didn't work you don't have an undo available.[-]")
			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - Botman commands ====")
		if debug then dbug("Registering help - Botman commands") end

		tmp.topicDescription = "The Botman mod adds special features to the bot such as hiding commands from chat, digging big holes and lots more.\n"
		tmp.topicDescription = tmp.topicDescription .. "The bot will work just fine without it."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'Botman'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('Botman', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	end
	-- ##################################################################

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "botman" then
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
		irc_chat(chatvars.ircAlias, "Botman Mod Commands:")
		irc_chat(chatvars.ircAlias, "====================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "botman")
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SavePrefab()

	if result then
		if debug then dbug("debug cmd_SavePrefab triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetChatColours()

	if result then
		if debug then dbug("debug cmd_SetChatColours triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearHorde()

	if result then
		if debug then dbug("debug cmd_SetClearHorde triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SpawnHorde()

	if result then
		if debug then dbug("debug cmd_SpawnHorde triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxClans()

	if result then
		if debug then dbug("debug cmd_SetMaxClans triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMaxClanPlayers()

	if result then
		if debug then dbug("debug cmd_SetMaxClanPlayers triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMinClanLevel()

	if result then
		if debug then dbug("debug cmd_SetMinClanLevel triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetResetDelay()

	if result then
		if debug then dbug("debug cmd_SetResetDelay triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetMapColour()

	if result then
		if debug then dbug("debug cmd_SetMapColour triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleAnticheat()

	if result then
		if debug then dbug("debug cmd_ToggleAnticheat triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleClans()

	if result then
		if debug then dbug("debug cmd_ToggleClans triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleMapping()

	if result then
		if debug then dbug("debug cmd_ToggleMapping triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleResetRegions()

	if result then
		if debug then dbug("debug cmd_ToggleResetRegions triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleResetRegionsClaims()

	if result then
		if debug then dbug("debug cmd_ToggleResetRegionsClaims triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleResetRegionsPrefabs()

	if result then
		if debug then dbug("debug cmd_ToggleResetRegionsPrefabs triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleMutePlayer()

	if result then
		if debug then dbug("debug cmd_ToggleMutePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideCommands()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideCommands triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	result = cmd_AddRemoveTraderProtection()

	if result then
		if debug then dbug("debug cmd_AddRemoveTraderProtection triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_CancelMaze()

	if result then
		if debug then dbug("debug cmd_CancelMaze triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteSave()

	if result then
		if debug then dbug("debug cmd_DeleteSave triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_DigFill()

	if result then
		if debug then dbug("debug cmd_DigFill triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_EraseArea()

	if result then
		if debug then dbug("debug cmd_EraseArea triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListItems()

	if result then
		if debug then dbug("debug cmd_ListItems triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListSaves()

	if result then
		if debug then dbug("debug cmd_ListSaves triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_LoadPrefab()

	if result then
		if debug then dbug("debug cmd_LoadPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_MakeMaze()

	if result then
		if debug then dbug("debug cmd_MakeMaze triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPlayer()

	if result then
		if debug then dbug("debug cmd_ResetPlayer triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetPrefab()

	if result then
		if debug then dbug("debug cmd_ResetPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_ResetRegionsNow()

	if result then
		if debug then dbug("debug cmd_ResetRegionsNow triggered") end
		return result
	end

	if (debug) then dbug("debug botman line " .. debugger.getinfo(1).currentline) end

	result = cmd_Undo()

	if result then
		if debug then dbug("debug cmd_Undo triggered") end
		return result
	end

	if debug then dbug("debug botman end") end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Botman commands help registered ****")
		if debug then dbug("Botman commands help registered") end
		topicID = topicID + 1
	end

	-- can't touch dis
	if true then
		-- HAMMER TIME!
		return result
	end
end
