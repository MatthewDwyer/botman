--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

local shortHelp = false
local skipHelp = false
local tmp = {}
local debug, prefix, suffix

-- enable debug to see where the code is stopping. Any error will be after the last debug line.
debug = false -- should be false unless testing

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
		cmd = prefix .. "pblock " .. wall .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos - 1 .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. suffix
		if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
      else
		cmd = prefix .. "pblock " .. fill .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos - 1 .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. suffix
		if botman.dbConnected then conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')") end
      end
    end
  end
end

local function renderMaze(wallBlock, x, y, z, width, length, height, fillBlock)
	local k, v, mazeX, mazeZ, block, maze, cmd

	makeMaze(width, length, x, y, z, wallBlock, fillBlock, height)
end

function mutePlayer(steam)
	send(prefix .. "mpc " .. steam .. " true")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	players[steam].mute = true
	irc_chat(server.ircMain, players[steam].name .. "'s chat has been muted :D")
	message("pm " .. steam .. " [" .. server.warnColour .. "]Your chat has been muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 1 WHERE steam = " .. steam) end
end


function unmutePlayer(steam)
	send(prefix .. "mpc " .. steam .. " false")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	players[steam].mute = false
	irc_chat(server.ircMain, players[steam].name .. "'s chat is no longer muted D:")
	message("pm " .. steam .. " [" .. server.chatColour .. "]Your chat is no longer muted.[-]")
	if botman.dbConnected then conn:execute("UPDATE players SET mute = 0 WHERE steam = " .. steam) end
end


function gmsg_coppi()
	calledFunction = "gmsg_coppi"
	prefix = ""
	suffix = " 0"
	result = false
	tmp = {}

	if botman.debugAll then
		debug = true -- this should be true
	end

	if server.coppiRelease == "Mod Coppis command additions Light" or tonumber(server.coppiVersion) > 4.4 then
		prefix = "cp-"
		suffix = ""
	end

-- ################## coppi's command functions ##################

	local function cmd_AddRemoveTraderProtection()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}trader protect/unprotect/remove {named area}"
			help[2] = "After marking out a named area with the {#}mark command, you can add or remove trader protection on it.\n"
			help[2] = help[2] .. "The protected area will only cover the area marked out, not all the way to bedrock."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "trade,prot,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "trade") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prote"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "trader" and (chatvars.words[2] == "protect" or chatvars.words[2] == "unprotect" or chatvars.words[2] == "remove") then
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
				if chatvars.words[2] == "protect" then
					send(prefix .. "safe add " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].y1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].y2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You added trader protection on a marked area called " .. tmp.name .. ".[-]")
				else
					send(prefix .. "safe del " .. prefabCopies[chatvars.playerid .. tmp.name].x1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].x2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].y1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].y2 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z1 .. " " .. prefabCopies[chatvars.playerid .. tmp.name].z2)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You removed trader protection on a marked area called " .. tmp.name .. ".[-]")
				end
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "maze,stop,canc,abor"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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


	local function cmd_DigFill() -- diggy diggy hole
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
			help[2] = help[2] .. " {#}fill east base 70 wide 2 tall 10 long 50 block steelBlock\n"
			help[2] = help[2] .. " {#}fill bedrock wide 2 block stone\n"
			help[2] = help[2] .. " {#}fill {saved prefab} block stone\n"
			help[2] = help[2] .. ".\n"
			help[2] = help[2] .. "You can repeat the last command with /again and change direction with /again west\n"
			help[2] = help[2] .. "."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "dig,fill,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "dig") or string.find(chatvars.command, "fill") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			tmp.prefab = ""
			tmp.base = chatvars.intY - 1
			tmp.tall = chatvars.intY + 5
			tmp.block = chatvars.words[3]
			tmp.direction = ""
			tmp.width = 5
			tmp.long = 5

			if prefabCopies[chatvars.playerid .. chatvars.words[2]] then
				tmp.prefab = chatvars.playerid .. chatvars.words[2]
			end

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "wide" or chatvars.words[i] == "width"  then
					tmp.width = chatvars.words[i+1]

					-- allow for width of 1
					tmp.width = math.abs(tmp.width)
					if tmp.width > 0 then tmp.width = tmp.width - 1 end

					-- default to same height
					tmp.tall = tmp.width
				end

				if chatvars.words[i] == "prefab" then
					tmp.prefab = chatvars.playerid .. chatvars.words[i+1]
				end

				if chatvars.words[i] == "replace" then
					tmp.newblock = chatvars.words[i+1]
				end

				if chatvars.words[i] == "block" then
					tmp.block = chatvars.words[i+1]
				end

				if chatvars.words[i] == "tall" or chatvars.words[i] == "deep" or chatvars.words[i] == "height" or chatvars.words[i] == "hieght" then
					tmp.tall = chatvars.words[i+1]

					-- allow for height of 1
					tmp.tall = math.abs(tmp.tall)
					if tmp.tall > 0 then tmp.tall = tmp.tall - 1 end
				end

				if chatvars.words[i] == "base" or chatvars.words[i] == "floor" or chatvars.words[i] == "bottom" then
					tmp.base = chatvars.words[i+1]
				end

				if chatvars.words[i] == "long" or chatvars.words[i] == "length" then
					tmp.long = chatvars.words[i+1]

					-- allow for length of 1
					tmp.long = math.abs(tmp.long)
					if tmp.long > 0 then tmp.long = tmp.long - 1 end
				end

				if chatvars.words[i] == "up" or chatvars.words[i] == "room" then
					tmp.direction = "up"
				end

				if chatvars.words[i] == "down" then
					tmp.direction = "down"
				end

				if chatvars.words[i] == "north" then
					tmp.direction = "north"
				end

				if chatvars.words[i] == "south" then
					tmp.direction = "south"
				end

				if chatvars.words[i] == "east" then
					tmp.direction = "east"
				end

				if chatvars.words[i] == "west" then
					tmp.direction = "west"
				end

				if chatvars.words[i] == "bedrock" then
					tmp.direction = "bedrock"
				end
			end

			if tmp.prefab ~= "" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = prefabCopies[tmp.prefab].x1
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = prefabCopies[tmp.prefab].x2
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = prefabCopies[tmp.prefab].y1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = prefabCopies[tmp.prefab].y2
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = prefabCopies[tmp.prefab].z1
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = prefabCopies[tmp.prefab].z2

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
						send(prefix .. "prepblock " .. tmp.newblock .. " air " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. suffix)
					else
						send(prefix .. "pblock air " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. suffix)
					end

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				else
					if tmp.newblock then
						send(prefix .. "prepblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. suffix)
					else
						send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[tmp.prefab].x1 .. " " .. prefabCopies[tmp.prefab].x2 .. " " .. prefabCopies[tmp.prefab].y1 .. " " .. prefabCopies[tmp.prefab].y2 .. " " .. prefabCopies[tmp.prefab].z1 .. " " .. prefabCopies[tmp.prefab].z2 .. suffix)
					end

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "bedrock" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX + tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = 3
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = chatvars.intY
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.width

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					if tmp.newblock then
					--prepblock <block_to_be_replaced> <block_name> <x1> <x2> <y1> <y2> <z1> <z2> <rot>
						send(prefix .. "prepblock " .. tmp.newblock .. " air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
					else
						send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
					end

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				else
					if tmp.newblock then
						send(prefix .. "prepblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
					else
						send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
					end

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "up" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX + tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = chatvars.intY - 1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = (chatvars.intY - 1) + tmp.tall
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.width

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "down" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX + tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = chatvars.intY - 1
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = chatvars.intY - tmp.long
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.width

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "north" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX + tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = tmp.base
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = tmp.base + tmp.tall
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.long

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				--botman.lastBlockCommandOwner = chatvars.playerid

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "south" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX + tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = tmp.base
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = tmp.base + tmp.tall
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ - tmp.long

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				--botman.lastBlockCommandOwner = chatvars.playerid

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "east" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX + tmp.long
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = tmp.base
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = tmp.base + tmp.tall
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.width

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				botman.faultyChat = false
				return true
			end

			if tmp.direction == "west" then
				prefabCopies[chatvars.playerid .. "bottemp"] = {}
				prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
				prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX
				prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX - tmp.long
				prefabCopies[chatvars.playerid .. "bottemp"].y1 = tmp.base
				prefabCopies[chatvars.playerid .. "bottemp"].y2 = tmp.base + tmp.tall
				prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - tmp.width
				prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + tmp.width

				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[1] == "dig" then
					send(prefix .. "pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				else
					send(prefix .. "pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. suffix)
				end

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				botman.faultyChat = false
				return true
			end
		end
	end


	local function cmd_EraseArea()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}erase {optional number} (default 5)\n"
			help[1] = help[1] .. " {#}erase block {block name} replace {with other block name} {optional number}\n"
			help[1] = help[1] .. "eg. {#}erase block stone replace air 20\n"
			help[2] = "Replace an area around you with air blocks.  Add a number to change the size."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "erase,block,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "erase") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			if chatvars.number == nil then
				chatvars.number = 5
			end

			for i=2,chatvars.wordCount,1 do
				if chatvars.words[i] == "block" then
					tmp.blockToErase = chatvars.words[i+1]
				end

				if chatvars.words[i] == "replace" then
					tmp.blockToReplace = chatvars.words[i+1]
				end
			end

			prefabCopies[chatvars.playerid .. "bottemp"] = {}
			prefabCopies[chatvars.playerid .. "bottemp"].owner = chatvars.playerid
			prefabCopies[chatvars.playerid .. "bottemp"].name = "bottemp"
			prefabCopies[chatvars.playerid .. "bottemp"].x1 = chatvars.intX - chatvars.number
			prefabCopies[chatvars.playerid .. "bottemp"].x2 = chatvars.intX + chatvars.number
			prefabCopies[chatvars.playerid .. "bottemp"].y1 = chatvars.intY - chatvars.number
			prefabCopies[chatvars.playerid .. "bottemp"].y2 = chatvars.intY + chatvars.number
			prefabCopies[chatvars.playerid .. "bottemp"].z1 = chatvars.intZ - chatvars.number
			prefabCopies[chatvars.playerid .. "bottemp"].z2 = chatvars.intZ + chatvars.number

			send(prefix .. "pexport " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. " " .. chatvars.playerid .. "bottemp")

			if tmp.blockToErase ~= nil then
				if tmp.blockToReplace == nil then
					send(prefix .. "prepblock " .. tmp.blockToErase .. " air " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. suffix)
				else
					send(prefix .. "prepblock " .. tmp.blockToErase .. " " .. tmp.blockToReplace .. " " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. suffix)
				end
			else
				send(prefix .. "pblock air " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. suffix)
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 2
			end

			--botman.lastBlockCommandOwner = chatvars.playerid

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


			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "dig,fill,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fix") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "bed"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			send(prefix .. "pblock 12 " .. tmp.x1 .. " " .. tmp.x2 .. " " .. tmp.y1 .. " " .. tmp.y2 .. " " .. tmp.z1 .. " " .. tmp.z2 .. suffix)

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
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


			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,item,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
			send("li " .. chatvars.words[2])

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_ListSaves() -- tested
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}list saves {optional player name}"
			help[2] = "List all your saved prefabs or those of someone else.  This list is coordinate pairs of places in the world that you have marked for some block command.\n"
			help[2] = help[2] .. "You can use a named save with the block commands."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "list,save,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
				if tmp.pid ~= 0 then
					cursor,errorString = conn:execute("select * from prefabCopies where owner = " .. tmp.pid)

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saved prefabs created by " .. tmp.name .. ":[-]")
					else
						irc_chat(chatvars.ircAlias, "Saved prefabs created by " .. tmp.name)
					end
				else
					cursor,errorString = conn:execute("select * from prefabCopies order by name")

					if (chatvars.playername ~= "Server") then
						message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saved prefabs:[-]")
					else
						irc_chat(chatvars.ircAlias, "Saved prefabs:")
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
					if tmp.pid == 0 then
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[row.owner].name .. ": " .. row.name .. "  P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "   P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, players[row.owner].name .. ": " .. row.name .. "  P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "  P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2)
						end
					else
						if (chatvars.playername ~= "Server") then
							message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. row.name .. "  P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "   P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2 .. "[-]")
						else
							irc_chat(chatvars.ircAlias, row.name .. "   P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. "  P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2)
						end
					end

					row = cursor:fetch(row, "a")
				end
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_LoadPrefab()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}load prefab {name}\n"
			help[1] = help[1] .. " {#}load prefab {name} at {x} {y} {z} face {0-3}\n"
			help[1] = help[1] .. " {#}load prefab {name} here\n"
			help[1] = help[1] .. "Everything after the prefab name is optional and if not given, the stored coords and rotation will be used."
			help[2] = "Restore a saved prefab in place or place it somewhere else.\n"
			help[2] = help[2] .. "If you provide coords and an optional rotation (default is 0 - north), you will make a new copy of the prefab at those coords.\n"
			help[2] = help[2] .. "If you instead add here, it will load on your current position with optional rotation.\n"
			help[2] = help[2] .. "If you instead add here, it will load on your current position with optional rotation.\n"
			help[2] = help[2] .. "If you only provide the name of the saved prefab, it will restore the prefab in place which replaces the original with the copy.\n"
			help[2] = help[2] .. "For perfect placement, stand at the south west corner before using this command."
			help[2] = help[2] .. ""

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "load,prefab,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "load") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "paste"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]For perfect placement, start from a south corner.[-]")
				botman.faultyChat = false
				return true
			end

			tmp.prefab = chatvars.words[3]
			tmp.face = 0
			tmp.coords = chatvars.intX .. " " .. chatvars.intY - 1 .. " " .. chatvars.intZ

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
				tmp.coords = chatvars.intX .. " " .. chatvars.intY - 1 .. " " .. chatvars.intZ
			end

			send(prefix .. "prender " .. chatvars.playerid .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face)
			send(prefix .. "prender " .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face)
			igplayers[chatvars.playerid].undoPrefab = true

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 2
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A prefab called " .. tmp.prefab .. " should have spawned.  If it didn't either the prefab isn't called " .. tmp.prefab .. " or it doesn't exist.[-]")

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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "make,maze,rand"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			renderMaze(tmp.wallBlock, tmp.x, tmp.y, tmp.z, tmp.width, tmp.length, tmp.height, tmp.fillBlock)

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MarkOutArea()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}mark {name} start/end or p1/p2"
			help[2] = "Mark out a named area to be used in other block or prefab commands\n"
			help[2] = help[2] .. "You can save it with {#}save {name} and recall it with {#}load prefab {name}\n"
			help[2] = help[2] .. "Mark two opposite corners of the area you wish to copy.  Move up or down between corners to add volume or stay at the same height to mark out a flat area."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "mark,start,end,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "mark" and (chatvars.words[3] == "start" or chatvars.words[3] == "end" or chatvars.words[3] == "p1" or chatvars.words[3] == "p2") then
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
				prefabCopies[chatvars.playerid .. chatvars.words[2]] = {}

				if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY -1
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " end[-]")
					if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY -1
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
					if botman.dbConnected then conn:execute("INSERT into prefabCopies (owner, name, x2, y2, z2) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")") end
				end
			else
				if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY -1
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " end[-]")
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET x1 = " .. chatvars.intX .. ", y1 = " .. chatvars.intY -1 .. ", z1 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'") end
				else
					prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
					prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
					prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
					prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY -1
					prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET x2 = " .. chatvars.intX .. ", y2 = " .. chatvars.intY -1 .. ", z2 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'") end
				end
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When done save it with " .. server.commandPrefix .. "save " .. chatvars.words[2] .. "[-]")

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_MoveBlock()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}move block {name of saved prefab} here\n"
			help[1] = help[1] .. " {#}move block {name of saved prefab} {x} {y} {z}\n"
			help[1] = help[1] .. " {#}move block {name of saved prefab} up (or down) {number}"
			help[2] = "Fills a saved block with air then renders it at the new position and updates the block's coordinates."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "move,block,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "block") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prefab"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
					irc_chat(chatvars.ircAlias, ".")
				end

				chatvars.helpRead = true
			end
		end

		if chatvars.words[1] == "move" and chatvars.words[2] == "block" then
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

			if prefabCopies[chatvars.playerid .. chatvars.words[3]] then
				-- first remove the original block by replacing it with air blocks
				send(prefix .. "pblock " .. 0 ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. suffix)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if chatvars.words[4] == "up" then
					prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number
					prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET y1 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number .. ", y2 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[3]) .. "'") end

					-- render the block at its new position
					send(prefix .. "pblock " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].blockName ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. suffix)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end

				if chatvars.words[4] == "down" then
					prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 - chatvars.number
					prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 - chatvars.number
					if botman.dbConnected then conn:execute("UPDATE prefabCopies SET y1 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number .. ", y2 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[3]) .. "'") end

					-- render the block at its new position
					send(prefix .. "pblock " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].blockName ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. suffix)

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
				end
			else
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
			end

			botman.faultyChat = false
			return true
		end
	end


	local function cmd_SavePrefab()
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}save {name}"
			help[2] = "After marking out the area you want to copy, you can save it."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "save,prefab,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
				send(prefix .. "pexport " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].name)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You saved a prefab called " .. chatvars.words[2] .. ".[-]")
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,clear,chat,colo"
				tmp.accessLevel = 1
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
						send(prefix .. "cpc " .. k .. " FFFFFF 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. tmp.pid .. " FFFFFF 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

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
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. tmp.pid .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

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
							send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end
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
					if (accessLevel(k) > 3 and accessLevel(k) < 11) and string.sub(v.chatColour, 1, 6) == "FFFFFF" then
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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
						send(prefix .. "cpc " .. k .. " " .. tmp.colour .. " 1")

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "set,clear,horde"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "spawn,horde"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
						send(prefix .. "sh " .. math.floor(igplayers[tmp.id].xPos) .. " " .. math.floor(igplayers[tmp.id].yPos) .. " " .. math.floor(igplayers[tmp.id].zPos) .. " " .. chatvars.number)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

						irc_chat(server.ircMain, "Horde spawned by bot at " .. igplayers[tmp.id].name .. "'s position at " .. math.floor(igplayers[tmp.id].xPos) .. " " .. math.floor(igplayers[tmp.id].yPos) .. " " .. math.floor(igplayers[tmp.id].zPos))
					end
				else
					tmp.loc = LookupLocation(chatvars.words[3])
					if tmp.loc ~= nil then
						send(prefix .. "sh " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z .. " " .. chatvars.number)

						if botman.getMetrics then
							metrics.telnetCommands = metrics.telnetCommands + 1
						end

						irc_chat(server.ircMain, "Horde spawned by bot at " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z)
					end
				end
			else
				-- spawn horde on self
				if (chatvars.playername ~= "Server") then
					if igplayers[chatvars.playerid].horde ~= nil then
						send(prefix .. "sh " .. igplayers[chatvars.playerid].horde .. " " .. chatvars.number)
					else
						send(prefix .. "sh " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " " .. chatvars.number)
					end

					if botman.getMetrics then
						metrics.telnetCommands = metrics.telnetCommands + 1
					end
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "mute,play"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "mute")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "show,hide,comm"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 0
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "comm")) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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
				send(prefix .. "tcch " .. server.commandPrefix)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if botman.dbConnected then conn:execute("UPDATE server SET hideCommands = 1") end

				if (chatvars.playername ~= "Server") then
					message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now hidden from global chat.[-]")
				else
					irc_chat(server.ircMain, "Bot commands are now hidden from global chat.")
				end
			else
				send(prefix .. "tcch")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

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
		if (chatvars.showHelp and not skipHelp) or botman.registerHelp then
			help = {}
			help[1] = " {#}undo\n"
			help[1] = help[1] .. " {#}undo save (restores saved chunks)"
			help[2] = "The block commands prender, pdup and pblock allow for the last command to be undone, however since more than one person can command the bot to do block commands\n"
			help[2] = help[2] .. "it is possible that other block commands have been done by the bot since your last block command.  If the last block command came from you, the bot will undo it.\n"
			help[2] = help[2] .. "Undo save will restore the saved area even if Coppi's undo can't be used due to another prefab or block command being used. Note: Even this has limits."

			if botman.registerHelp then
				tmp.command = help[1]
				tmp.keywords = "undo,save,coppi"
				tmp.accessLevel = 2
				tmp.description = help[2]
				tmp.notes = ""
				tmp.ingameOnly = 1
				registerHelp(tmp)
			end

			if (chatvars.words[1] == "help" and (string.find(chatvars.command, "undo") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
				irc_chat(chatvars.ircAlias, help[1])

				if not shortHelp then
					irc_chat(chatvars.ircAlias, help[2])
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

			if igplayers[chatvars.playerid].undoPrefab then
				send(prefix .. "prender " .. chatvars.playerid .. "bottemp" .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1  .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1)
			else
				send("pundo")
				igplayers[chatvars.playerid].undoPrefab = nil
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Block undo command (pundo) sent. If it didn't work you don't have an undo available.[-]")
			botman.faultyChat = false
			return true
		end
	end

-- ################## End of command functions ##################

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "==== Registering help - Coppi's commands ====")
		dbug("Registering help - coppi's commands")

		tmp = {}
		tmp.topicDescription = "Coopi's mod adds many great features to the server. The bot provides helper commands to free you from the console and it can combine several console commands into one bot command."

		cursor,errorString = conn:execute("SELECT * FROM helpTopics WHERE topic = 'coppi'")
		rows = cursor:numrows()
		if rows == 0 then
			cursor,errorString = conn:execute("SHOW TABLE STATUS LIKE 'helpTopics'")
			row = cursor:fetch(row, "a")
			tmp.topicID = row.Auto_increment

			conn:execute("INSERT INTO helpTopics (topic, description) VALUES ('coppi', '" .. escape(tmp.topicDescription) .. "')")
		end
	end

	-- don't proceed if there is no leading slash
	if (string.sub(chatvars.command, 1, 1) ~= server.commandPrefix and server.commandPrefix ~= "") then
		botman.faultyChat = false
		return false
	end

	if chatvars.showHelp then
		if chatvars.words[3] then
			if chatvars.words[3] ~= "coppi" then
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
		irc_chat(chatvars.ircAlias, "Coppi's Mod Commands:")
		irc_chat(chatvars.ircAlias, "=====================")
		irc_chat(chatvars.ircAlias, ".")
	end

	if chatvars.showHelpSections then
		irc_chat(chatvars.ircAlias, "coppi")
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_AddRemoveTraderProtection()

	if result then
		if debug then dbug("debug cmd_AddRemoveTraderProtection triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleMutePlayer()

	if result then
		if debug then dbug("debug cmd_ToggleMutePlayer triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_SpawnHorde()

	if result then
		if debug then dbug("debug cmd_SpawnHorde triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_ToggleShowHideCommands()

	if result then
		if debug then dbug("debug cmd_ToggleShowHideCommands triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetChatColours()

	if result then
		if debug then dbug("debug cmd_SetChatColours triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_MakeMaze()

	if result then
		if debug then dbug("debug cmd_MakeMaze triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_CancelMaze()

	if result then
		if debug then dbug("debug cmd_CancelMaze triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_SetClearHorde()

	if result then
		if debug then dbug("debug cmd_SetClearHorde triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_Undo()

	if result then
		if debug then dbug("debug cmd_Undo triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListSaves()

	if result then
		if debug then dbug("debug cmd_ListSaves triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_MarkOutArea()

	if result then
		if debug then dbug("debug cmd_MarkOutArea triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_SavePrefab()

	if result then
		if debug then dbug("debug cmd_SavePrefab triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_LoadPrefab()

	if result then
		if debug then dbug("debug cmd_LoadPrefab triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_ListItems()

	if result then
		if debug then dbug("debug cmd_ListItems triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_MoveBlock()

	if result then
		if debug then dbug("debug cmd_MoveBlock triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_EraseArea()

	if result then
		if debug then dbug("debug cmd_EraseArea triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_DigFill()

	if result then
		if debug then dbug("debug cmd_DigFill triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	result = cmd_FixBedrock()

	if result then
		if debug then dbug("debug cmd_FixBedrock triggered") end
		return result
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	-- ###################  Staff only beyond this point ################
	-- Don't proceed if this is a player.  Server and staff only here.
	if (chatvars.playername ~= "Server") then
		if (chatvars.accessLevel > 2) then
			botman.faultyChat = false
			return false
		end
	end
	-- ##################################################################


	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
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
				player[chatvars.playerid].markY = players[pid].yPos - 1
				player[chatvars.playerid].markZ = players[pid].zPos
			else
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No player found called " .. tmp.name .. "[-]")
				botman.faultyChat = false
				return true
			end
		else
			player[chatvars.playerid].markX = chatvars.intX
			player[chatvars.playerid].markY = chatvars.intY - 1
			player[chatvars.playerid].markZ = chatvars.intZ
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set p1")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "p1" and (chatvars.playerid ~= 0) then
		player[chatvars.playerid].p1X = chatvars.intX
		player[chatvars.playerid].p1Y = chatvars.intY - 1
		player[chatvars.playerid].p1Z = chatvars.intZ

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]P1 position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
			irc_chat(chatvars.ircAlias, " " .. server.commandPrefix .. "set p2")

			if not shortHelp then
				irc_chat(chatvars.ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(chatvars.ircAlias, ".")
			end
		end
	end

	if chatvars.words[1] == "set" and chatvars.words[2] == "p2" and (chatvars.playerid ~= 0) then
		player[chatvars.playerid].p2X = chatvars.intX
		player[chatvars.playerid].p2Y = chatvars.intY - 1
		player[chatvars.playerid].p2Z = chatvars.intZ

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]P2 position stored.  See block commands for its proper usage.[-]")

		botman.faultyChat = false
		return true
	end

	if botman.registerHelp then
		irc_chat(chatvars.ircAlias, "**** Coppi's commands help registered ****")
		dbug("Coppi's commands help registered")
		topicID = topicID + 1
	end

	if debug then dbug("debug coppi end") end

	-- can't touch dis
	if true then
		return result
	end

end
