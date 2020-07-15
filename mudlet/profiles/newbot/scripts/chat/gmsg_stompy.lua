--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- bc-go Items /filter=Name
-- bc-go itemclasses /filter=id,name /min

local shortHelp = false
local skipHelp = false
local tmp = {}
local debug, result

debug = false -- should be false unless testing

function gmsg_stompy()
	calledFunction = "gmsg_stompy"
	result = false

	if botman.debugAll then
		debug = true -- this should be true
	end

-- ################## BC mod command functions ##################

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
			cmd = "bc-block fill " .. xPos + i .. " " .. yPos .. " " .. zPos + j .. " " .. xPos + i .. " " .. yPos + tall .. " " .. zPos + j .. " " .. wall

			if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
		  else
			cmd = "bc-block fill " .. xPos + i .. " " .. yPos .. " " .. zPos + j .. " " .. xPos + i .. " " .. yPos + tall .. " " .. zPos + j .. " " .. fill
			if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
		  end
		end
	  end
	end

	local function renderMaze(wallBlock, x, y, z, width, length, height, fillBlock)
		local k, v, mazeX, mazeZ, block, maze, cmd

		makeMaze(width, length, x, y, z, wallBlock, fillBlock, height)
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
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


	local function cmd_AddRemoveTraderProtection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}trader protect/unprotect/remove {named area}\n"
			help[1] = " {#}trader add/trader del {named area}"
			help[2] = "After marking out a named area with the {#}mark command, you can add or remove trader protection on it.\n"

			tmp.command = help[1]
			tmp.keywords = "trade,prot,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "trade") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "prote"))) or chatvars.words[1] ~= "help" then
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

			if not prefabCopies[chatvars.playerid .. tmp.name] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked an area called " .. tmp.name .. ". Please do that first.[-]")
			else
				if chatvars.words[2] == "protect" or chatvars.words[2] == "add" then
					sendCommand("bc-protect " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2 .. " true")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added trader protection on a marked area called " .. tmp.name .. ".[-]")
				else
					sendCommand("bc-protect " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2 .. " false")
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed trader protection on a marked area called " .. tmp.name .. ".[-]")
				end

				igplayers[chatvars.playerid].undoPrefab = false
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
			tmp.keywords = "del,list,save,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "list") or string.find(chatvars.command, "dele"))) or chatvars.words[1] ~= "help" then
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
			tmp.keywords = "dig,fill,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "dig") or string.find(chatvars.command, "fill") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy"))) or chatvars.words[1] ~= "help" then
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end

				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
						sendCommand("bc-block fill " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z2 .. " " .. tmp.block .. " " ..  tmp.newblock)
					else
						sendCommand("bc-block fill " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z2 .. " " .. tmp.block)
					end
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z2 .. " " .. tmp.newblock .. " " .. tmp.block)
					else
						sendCommand("bc-block fill " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z2 .. " " .. tmp.block)
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
						sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " ..  tmp.newblock .. " " .. tmp.block)
					else
						sendCommand("bc-block fill " ..  x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block)
					end
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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

				sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
				if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
				igplayers[chatvars.playerid].undoPrefab = false

				if chatvars.words[1] == "dig" then
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " * air")
				else
					if tmp.newblock then
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " " .. tmp.newblock)
					else
						sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.block .. " *")
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
			tmp.keywords = "erase,block,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "erase") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy"))) or chatvars.words[1] ~= "help" then
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

			sendCommand("bc-export " .. chatvars.playerid .. "bottemp " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
			if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'bottemp'," .. x1 .. "," .. y1 .. "," .. z1 .. ")") end
			igplayers[chatvars.playerid].undoPrefab = false

			if tmp.blockToErase ~= nil then
				if tmp.blockToReplace == nil then
					sendCommand("bc-block swap " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " air " .. tmp.blockToErase)
				else
					sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " " .. tmp.blockToReplace .. " " .. tmp.blockToErase)
				end
			else
				sendCommand("bc-block fill " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2 .. " air *")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_FixBedrock()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}fix bedrock {distance}"
			help[2] = "You can replace the bedrock layer below you up to {distance} away from your position.\n"
			help[2] = help[2] .. "You only need to be over the area to be fixed.  No other layers are touched."

			tmp.command = help[1]
			tmp.keywords = "dig,fill,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fix") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "bed"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "fix" and chatvars.words[2] == "bedrock" then
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

			if chatvars.number == nil then
				chatvars.number	= 40
			end

			tmp = {}
			tmp.x1 = chatvars.intX - chatvars.number
			tmp.x2 = chatvars.intX + chatvars.number
			tmp.y1 = 0
			tmp.y2 = 2
			tmp.z1 = chatvars.intZ - chatvars.number
			tmp.z2 = chatvars.intZ + chatvars.number

			igplayers[chatvars.playerid].undoPrefab = false

			if tonumber(server.gameVersionNumber) < 17 then
				sendCommand("bc-block fill " .. tmp.x1 .. " " .. tmp.y1 .. " " .. tmp.z1 .. " " .. tmp.x2 .. " " .. tmp.y2 .. " " .. tmp.z2 .. " " .. " air bedrock")
			else
				sendCommand("bc-block fill " .. tmp.x1 .. " " .. tmp.y1 .. " " .. tmp.z1 .. " " .. tmp.x2 .. " " .. tmp.y2 .. " " .. tmp.z2 .. " " .. " air terrBedrock")
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
			tmp.keywords = "list,item,stompy"
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


	local function cmd_ListSaves() -- tested
		local name, counter, cursor, errorString, row

		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list saves {optional player name}"
			help[2] = "List all your saved marked areas or those of someone else.  This list is coordinate pairs of places in the world that you have marked for some block command.\n"
			help[2] = help[2] .. "You can use a named save with the block commands.\n"
			help[2] = help[2] .. "You can teleport to them with {#}tp #{name of marked area}.\n"
			help[2] = help[2] .. "You can delete one {#}delete save {list number of marked area}."

			tmp.command = help[1]
			tmp.keywords = "list,save,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 0

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
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
			tmp.keywords = "load,prefab,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "load") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "paste"))) or chatvars.words[1] ~= "help" then
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
			tmp.options = ""

			if (prefabCopies[chatvars.playerid .. chatvars.words[3]]) and not (string.find(chatvars.command, " at ")) then
				if tonumber(prefabCopies[chatvars.playerid .. chatvars.words[3]].y1) < tonumber(prefabCopies[chatvars.playerid .. chatvars.words[3]].y2) then
					tmp.coords = prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1
				else
					tmp.coords = prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2
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

			sendCommand("bc-import " .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face .. tmp.options)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A prefab called " .. chatvars.wordsOld[3] .. " should have spawned.  If it didn't either the prefab isn't called " .. tmp.prefab .. " or it doesn't exist.[-]")
			igplayers[chatvars.playerid].undoPrefab = true
			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MakeMaze() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}make maze (default maze 20 x 20)\n"
			help[1] = help[1] .. " {#}make maze wall {block name} fill {air block} width {number} length {number} height {number} x {x coord} y {y coord} z {z coord}\n"
			help[1] = help[1] .. "The bot also accepts wide, long, and tall instead of width, length, and height."
			help[2] = "Generate and build a random maze.  Someone must stay there until the maze completes or it will fail to spawn fully.\n"
			help[2] = help[2] .. "Default values: wall steelBlock fill air width 20 length 20 height 3. It uses your current position for x, y and z if not given."

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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
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

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "wall" then
					tmp.wallBlock = chatvars.words[i+1]
				end

				if chatvars.words[i] == "fill" then
					tmp.fillBlock = chatvars.words[i+1]
				end

				if chatvars.words[i] == "x" then
					tmp.x = chatvars.words[i+1]
				end

				if chatvars.words[i] == "y" then
					tmp.y = chatvars.words[i+1]
				end

				if chatvars.words[i] == "z" then
					tmp.z = chatvars.words[i+1]
				end

				if chatvars.words[i] == "width" or chatvars.words[i] == "wide" then
					tmp.width = chatvars.words[i+1]
				end

				if chatvars.words[i] == "length" or chatvars.words[i] == "long" then
					tmp.length = chatvars.words[i+1]
				end

				if chatvars.words[i] == "height" or chatvars.words[i] == "tall" then
					tmp.height = chatvars.words[i+1]
				end
			end

			igplayers[chatvars.playerid].undoPrefab = false
			renderMaze(tmp.wallBlock, tmp.x, tmp.y, tmp.z, tmp.width, tmp.length, tmp.height, tmp.fillBlock)

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
			tmp.keywords = "save,prefab,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
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

				sendCommand("bc-export " .. chatvars.words[2] .. " " .. x1 .. " " .. y1 .. " " .. z1 .. " " .. x2 .. " " .. y2 .. " " .. z2)
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
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
						sendCommand("bc-spawn horde /player=" .. tmp.id .. " /count=" .. tmp.number)
						irc_chat(server.ircMain, "Horde spawned by bot at " .. igplayers[tmp.id].name .. "'s position at " .. igplayers[tmp.id].xPos .. " " .. igplayers[tmp.id].yPos .. " " .. igplayers[tmp.id].zPos)
					end
				else
					tmp.loc = LookupLocation(chatvars.words[3])
					if tmp.loc ~= nil then
						sendCommand("bc-spawn horde " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z .. " /count=" .. tmp.number)
						irc_chat(server.ircMain, "Horde spawned by bot at " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z)
					end
				end
			else
				-- spawn horde on self
				if (chatvars.playername ~= "Server") then
					sendCommand("bc-spawn horde /player=" .. chatvars.playerid .. " " .. tmp.number)
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "mute")) or chatvars.words[1] ~= "help" then
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

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "stompy") or string.find(chatvars.command, "comm")) or chatvars.words[1] ~= "help" then
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
			help[1] = " {#}undo {optional name of saved (marked) area}"
			help[2] = "Undo your last block command."

			tmp.command = help[1]
			tmp.keywords = "undo,save,stompy"
			tmp.accessLevel = 2
			tmp.description = help[2]
			tmp.notes = ""
			tmp.ingameOnly = 1

			help[3] = helpCommandRestrictions(tmp)

			if botman.registerHelp then
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "undo") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, help[3])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "undo" then
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

			if igplayers[chatvars.playerid].undoPrefab then
				sendCommand("bc-undo")
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Your last prefab command has been undone.[-]")
				botman.faultyChat = false
				return true
			end

			restoreName = ""

			if chatvars.words[2] then
				restoreName = chatvars.playerid .. chatvars.words[2]
			end

			if restoreName ~= "" then
				sendCommand("bc-import " .. restoreName .. " " .. prefabCopies[restoreName].x1 .. " " .. prefabCopies[restoreName].y1 .. " " .. prefabCopies[restoreName].z1 .. " /ne")
			else
				sendCommand("bc-import " .. chatvars.playerid .. "bottemp " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " /ne")
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]The block command has been undone.[-]")
			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - BC commands ====")
		if debug then dbug("Registering help - BC commands") end

		tmp.topicDescription = "The BC mod adds special features to the bot such as hiding commands from chat, digging big holes and lots more.\n"
		tmp.topicDescription = tmp.topicDescription .. "The bot will work just fine without it."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'BC'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('BC', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

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
			if chatvars.words[3] ~= "stompy" then
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
		irc_chat(chatvars.ircAlias, "Stompy's BC Mod Commands:")
		irc_chat(chatvars.ircAlias, "=========================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "stompy")
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_DigFill()

	if result then
		if debug then dbug("debug cmd_DigFill triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideCommands()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideCommands triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleMutePlayer()

	if result then
		if debug then dbug("debug cmd_ToggleMutePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetChatColours()

	if result then
		if debug then dbug("debug cmd_SetChatColours triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_SpawnHorde()

	if result then
		if debug then dbug("debug cmd_SpawnHorde triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

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

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_DeleteSave()

	if result then
		if debug then dbug("debug cmd_DeleteSave triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_EraseArea()

	if result then
		if debug then dbug("debug cmd_EraseArea triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_MakeMaze()

	if result then
		if debug then dbug("debug cmd_MakeMaze triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_CancelMaze()

	if result then
		if debug then dbug("debug cmd_CancelMaze triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixBedrock()

	if result then
		if debug then dbug("debug cmd_FixBedrock triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_Undo()

	if result then
		if debug then dbug("debug cmd_Undo triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListSaves()

	if result then
		if debug then dbug("debug cmd_ListSaves triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_SavePrefab()

	if result then
		if debug then dbug("debug cmd_SavePrefab triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearHorde()

	if result then
		if debug then dbug("debug cmd_SetClearHorde triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_LoadPrefab()

	if result then
		if debug then dbug("debug cmd_LoadPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListItems()

	if result then
		if debug then dbug("debug cmd_ListItems triggered") end
		return result
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy"))) or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set mark {optional player}")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(chatvars.ircAlias, "If you add a player name it will record their current position instead.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "mark" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[3] ~= nil then
			tmp.name = string.trim(chatvars.words[3])
			tmp.pid = LookupPlayer(tmp.name)

			if tmp.pid == 0 then
				tmp.pid = LookupArchivedPlayer(tmp.name)

				if not (tmp.pid == 0) then
					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.[-]")
					else
						irc_chat(chatvars.ircAlias, "Player " .. playersArchived[tmp.pid].name .. " was archived. Get them to rejoin the server and repeat this command.")
					end

					botman.faultyChat = false
					return true
				end
			end

			if tmp.pid ~= 0 then
				player[chatvars.playerid].markX = players[pid].xPos
				player[chatvars.playerid].markY = players[pid].yPos
				player[chatvars.playerid].markZ = players[pid].zPos
			else
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No player found called " .. tmp.name .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			player[chatvars.playerid].markX = chatvars.intX
			player[chatvars.playerid].markY = chatvars.intY
			player[chatvars.playerid].markZ = chatvars.intZ
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy"))) or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set p1")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "p1" and (chatvars.playerid ~= 0) then
		player[chatvars.playerid].p1X = chatvars.intX
		player[chatvars.playerid].p1Y = chatvars.intY
		player[chatvars.playerid].p1Z = chatvars.intZ

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]P1 position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug stompy line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "stompy"))) or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set p2")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "p2" and (chatvars.playerid ~= 0) then
		player[chatvars.playerid].p2X = chatvars.intX
		player[chatvars.playerid].p2Y = chatvars.intY
		player[chatvars.playerid].p2Z = chatvars.intZ

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]P2 position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if debug then dbug("debug stompy end") end
	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** BC commands help registered ****")
		if debug then dbug("BC commands help registered") end
		topicID = topicID + 1
	end

	-- can't touch dis
	if true then
		return result
	end
end
