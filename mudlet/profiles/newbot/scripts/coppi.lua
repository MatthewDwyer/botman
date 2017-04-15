--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

math.randomseed( os.time() )

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
 
  function walk(x, y)
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
		cmd = "pblock " .. wall .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos - 1 .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. " 0"
		conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')")						  
      else
		cmd = "pblock " .. fill .. " " .. xPos + i .. " " .. xPos + i+1 .. " " .. yPos - 1 .. " " .. yPos + tall - 1 .. " " .. zPos + j .. " " .. zPos + j+1 .. " 0"
		conn:execute("INSERT into miscQueue (steam, command) VALUES (0, '" .. escape(cmd) .. "')")						  		
      end
    end
  end
end

function renderMaze(wallBlock, x, y, z, width, length, height, fillBlock)
	local k, v, mazeX, mazeZ, block, maze, cmd	
	
	makeMaze(width, length, x, y, z, wallBlock, fillBlock, height)			
end

function mutePlayer(steam)
	send("mpc " .. steam .. " true")
	players[steam].mute = true
	irc_chat(server.ircMain, players[steam].name .. "'s chat has been muted :D")
	message("pm " .. steam .. " [" .. server.warnColour .. "]Your chat has been muted.[-]")
	conn:execute("UPDATE players SET mute = 1 WHERE steam = " .. steam)
end


function unmutePlayer(steam)
	send("mpc " .. steam .. " false")
	players[steam].mute = false
	irc_chat(server.ircMain, players[steam].name .. "'s chat is no longer muted D:")
	message("pm " .. steam .. " [" .. server.chatColour .. "]Your chat is no longer muted.[-]")
	conn:execute("UPDATE players SET mute = 0 WHERE steam = " .. steam)
end


function gmsg_coppi()
	calledFunction = "gmsg_coppi"

	local shortHelp = false
	local skipHelp = false
	local tmp = {}
	local debug
	
	debug = false

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
		irc_chat(players[chatvars.ircid].ircAlias, "")
		irc_chat(players[chatvars.ircid].ircAlias, "Coppi's Mod Commands:")
		irc_chat(players[chatvars.ircid].ircAlias, "=====================")
		irc_chat(players[chatvars.ircid].ircAlias, "")
	end

	if chatvars.showHelpSections then
		irc_chat(players[chatvars.ircid].ircAlias, "coppi")
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "mute")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "mute <player name>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "unmute <player name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Prevent a player using text chat or allow them to chat.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	 if (chatvars.words[1] == "mute" or chatvars.words[1] == "unmute") and chatvars.words[2] ~= nil then
		tmp.pname = string.sub(chatvars.command, string.find(chatvars.command, "mute ") + 5)
		tmp.pname = string.trim(tmp.pname)
		tmp.pid = LookupPlayer(tmp.pname)

		if tmp.pid == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No player found called " .. tmp.pname .. "[-]")
			else
				irc_chat(server.ircMain, "No player found called " .. tmp.pname)
			end

			botman.faultyChat = false
			return true
		end

		if chatvars.words[1] == "unmute" then
			unmutePlayer(tmp.pid)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. players[tmp.pid].name .. " can chat again D:[-]")
			end
		else
			mutePlayer(tmp.pid)

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Chat from player " .. players[tmp.pid].name .. " is blocked :D[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "spawn horde <optional player or location name> <number of zombies>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Spawn a horde around a player or location or at a marked coordinate.  See " .. server.commandPrefix .. "set horde.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "spawn" and (chatvars.words[2] == "horde") then
		if chatvars.words[3] ~= nil then
			tmp.pid = LookupPlayer(chatvars.words[3])
			if tmp.pid ~= nil then
				if igplayers[tmp.pid] then
					send("sh " .. math.floor(igplayers[tmp.pid].xPos) .. " " .. math.floor(igplayers[tmp.pid].yPos) .. " " .. math.floor(igplayers[tmp.pid].zPos) .. " " .. chatvars.number)
					irc_chat(server.ircMain, "Horde spawned by bot at " .. igplayers[tmp.pid].name .. "'s position at " .. math.floor(igplayers[tmp.pid].xPos) .. " " .. math.floor(igplayers[tmp.pid].yPos) .. " " .. math.floor(igplayers[tmp.pid].zPos))
				end
			else
				tmp.loc = LookupLocation(chatvars.words[3])
				if tmp.loc ~= nil then
					send("sh " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z .. " " .. chatvars.number)
					irc_chat(server.ircMain, "Horde spawned by bot at " .. locations[tmp.loc].x .. " " .. locations[tmp.loc].y .. " " .. locations[tmp.loc].z)
				end
			end
		else
			if (chatvars.playername ~= "Server") then
				if igplayers[chatvars.playerid].horde ~= nil then
					send("sh " .. igplayers[chatvars.playerid].horde .. " " .. chatvars.number)
				else
					send("sh " .. chatvars.intX .. " " .. chatvars.intY .. " " .. chatvars.intZ .. " " .. chatvars.number)
				end
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "comm")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "hide commands")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "show commands")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Hide commands from ingame chat which makes them all PM's or show them which makes them public.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "hide" or chatvars.words[1] == "show") and chatvars.words[2] == "commands" and chatvars.words[3] == nil  then
		server.hideCommands = true

		if chatvars.words[1] == "hide" then
			send("tcch " .. server.commandPrefix)
			conn:execute("UPDATE server SET hideCommands = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now hidden from global chat.[-]")
			else
				irc_chat(server.ircMain, "Bot commands are now hidden from global chat.")
			end
		else
			send("tcch")
			conn:execute("UPDATE server SET hideCommands = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Bot commands are now visible in global chat.[-]")
			else
				irc_chat(server.ircMain, "Bot commands are now visible in global chat.")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "phy")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "physics on")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "physics off")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable or disable physics on the server.  The state of physics is persistent across reboots.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "physics" and (chatvars.words[2] == "on" or chatvars.words[2] == "off") then
		if chatvars.words[2] == "off" then
			server.allowPhysics = false
			conn:execute("UPDATE server SET allowPhysics = 0")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Physics is disabled.[-]")
			else
				irc_chat(server.ircMain, "Physics is disabled.")
			end
		else
			server.allowPhysics = true
			conn:execute("UPDATE server SET allowPhysics = 1")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Physics is enabled.[-]")
			else
				irc_chat(server.ircMain, "Physics is enabled.")
			end
		end

		if server.coppi then
			send("py")
		end

		botman.faultyChat = false
		return true
	end
	
	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end
	
	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "chat") or string.find(chatvars.command, "colo")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set new player/player/donor/prisoner/mod/admin/owner chat colour FFFFFF")
			irc_chat(players[chatvars.ircid].ircAlias, "To disable automatic chat colouring, set it to white which is FFFFFF")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Enable or disable physics on the server.  The state of physics is persistent across reboots.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and string.find(chatvars.command, "chat col") then
		tmp = {}
		tmp.target = chatvars.words[2]
		
		if chatvars.words[2] == "new" then
			tmp.colour = chatvars.words[6]
		else
			tmp.colour = chatvars.words[5]		
		end
		
		if tmp.target ~= "new" and tmp.target ~= "player" and tmp.target ~= "donor" and tmp.target ~= "prisoner" and tmp.target ~= "mod" and tmp.target ~= "admin" and tmp.target ~= "owner" then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Missing target for chat colour.  Expected new player or player or donor or prisoner or mod or admin or owner.")
			end		
			
			botman.faultyChat = false
			return true					
		end
		
		if tmp.colour == nil then
			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]6 character hex colour code required eg. FFFFFF for white.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "6 character hex colour code required eg. FFFFFF for white.")
			end		
			
			botman.faultyChat = false
			return true			
		end

		-- strip out any # characters
		tmp.colour = tmp.colour:gsub("#", "")	

		if tmp.target == "new" then
			server.chatColourNewPlayer = tmp.colour
			conn:execute("UPDATE server SET chatColourNewPlayer = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]New player chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "New player chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end		
			
			for k,v in pairs(igplayers) do
				if accessLevel(k) == 99 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end			
		end
		
		if tmp.target == "player" then
			server.chatColourPlayer = tmp.colour
			conn:execute("UPDATE server SET chatColourPlayer = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Non-new player chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Non-new player chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end	

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 90 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end			
		end	

		if tmp.target == "donor" then
			server.chatColourDonor = tmp.colour
			conn:execute("UPDATE server SET chatColourDonor = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Donor chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Donor chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end

			for k,v in pairs(igplayers) do
				if accessLevel(k) > 3 and accessLevel(k) < 11 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end			
		end	

		if tmp.target == "prisoner" then
			server.chatColourPrisoner = tmp.colour
			conn:execute("UPDATE server SET chatColourPrisoner = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Prisoner chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Prisoner chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end

			for k,v in pairs(igplayers) do
				if players[k].prisoner and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end						
		end	
		
		if tmp.target == "mod" then
			server.chatColourMod = tmp.colour
			conn:execute("UPDATE server SET chatColourMod = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Moderator chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Moderator chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end	

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 2 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end			
		end

		if tmp.target == "admin" then
			server.chatColourAdmin = tmp.colour
			conn:execute("UPDATE server SET chatColourAdmin = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Admin chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Admin chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 1 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end			
		end

		if tmp.target == "owner" then
			server.chatColourOwner = tmp.colour
			conn:execute("UPDATE server SET chatColourOwner = '" .. escape(tmp.colour) .. "'")

			if (chatvars.playername ~= "Server") then
				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Owner chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.[-]")
			else
				irc_chat(players[chatvars.ircid].ircAlias, "Owner chat will be coloured " .. tmp.colour .. " if they haven't been assigned a colour of their own.")
			end	

			for k,v in pairs(igplayers) do
				if accessLevel(k) == 0 and string.upper(players[k].chatColour) == "FFFFFF" then
					send("cpc " .. k .. " " .. tmp.colour .. " 1")
				end
			end
		end		

		botman.faultyChat = false
		return true
	end
	
	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end		

	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == nil) then
		botman.faultyChat = false
		return false
	end
	-- ####################################################################################

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end
	
	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "make maze")
			irc_chat(players[chatvars.ircid].ircAlias, "Optional parts: wall <block name> fill <air block> width <number> length <number> height <number> x <x coord> y <y coord> z <z coord>")			
			irc_chat(players[chatvars.ircid].ircAlias, "Default values: wall steelBlock fill air width 20 length 20 height 3. It uses your current position for x, y and z if not given.")						

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Generate and build a random maze. ")
				irc_chat(players[chatvars.ircid].ircAlias, "It is very slow and someone must stay with it or it won't work.  Cancel it with " .. server.commandPrefix .. "stop maze")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end	
	
	if chatvars.words[1] == "make" and chatvars.words[2] == "maze" and (chatvars.playerid ~= 0) then
	
		if (chatvars.playername == "Server") then
			irc_chat(players[chatvars.ircid].ircAlias, "You can only use this command ingame.")
			botman.faultyChat = false
			return true		
		end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end
	
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
			
			if chatvars.words[i] == "width" then
				tmp.width = chatvars.words[i+1]
			end				
			
			if chatvars.words[i] == "length" then
				tmp.length = chatvars.words[i+1]
			end				

			if chatvars.words[i] == "height" then
				tmp.height = chatvars.words[i+1]
			end				
		end
		
	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end		
		
		renderMaze(tmp.wallBlock, tmp.x, tmp.y, tmp.z, tmp.width, tmp.length, tmp.height, tmp.fillBlock)			
		
	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end		

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end			

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "maze")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "stop maze")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Aborts any maze(s) that you have told the bot to create.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "stop" or chatvars.words[1] == "abort" or chatvars.words[1] == "cancel" and (chatvars.words[2] == "maze") and (chatvars.playerid ~= 0) then
		conn:execute("delete from miscQueue")

		if (chatvars.playername ~= "Server") then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Maze generation has been aborted.  You will need to clean up the mess yourself :)[-]")
		else
			irc_chat(players[chatvars.ircid].ircAlias, "Maze generation has been aborted.  You will need to clean up the mess yourself :)")
		end		

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end				

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and string.find(chatvars.command, "coppi") or string.find(chatvars.command, "horde")) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set/clear horde")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Marks your current position to spawn a horde ther with " .. server.commandPrefix .. "spawn horde.")
				irc_chat(players[chatvars.ircid].ircAlias, "Clear horde doesn't remove the horde. It only clears the saved coordinate.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "set" and (chatvars.words[2] == "horde") and (chatvars.playerid ~= 0) then
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

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "add") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "add prefab <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can copy an area of blocks to later recall them or to fill the area with a block.")
				irc_chat(players[chatvars.ircid].ircAlias, "This requires the latest Coppi's Additions and are not currently in Alloc's Mod.  You can give it any name but you can't reuse a name that is already defined by you.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	-- ###################  Block copy and paste commands ################

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "undo") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "block"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "undo")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "The block commands prender, pdup and pblock allow for the last command to be undone, however since more than one person can command the bot to do block commands")
				irc_chat(players[chatvars.ircid].ircAlias, "it is possible that other block commands have been done by the bot since your last block command.  If the last block command came from you, the bot will undo it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "undo" and (chatvars.words[2] == nil or chatvars.words[2] == "save") and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[2] == "save" then
			send("prender " .. chatvars.playerid .. "bottemp" .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1  .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " 0")
			botman.faultyChat = false
			return true
		end

		if botman.lastBlockCommandOwner == chatvars.playerid then
			send("pundo")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Block undo command (pundo) sent. If it didn't work you don't have an undo available.[-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No undo available.  Use " .. server.commandPrefix .. "undo save.[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "list"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list saves <optional player name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all your saved prefabs or those of someone else.  This list is coordinate pairs of places in the world that you have marked for some block command.")
				irc_chat(players[chatvars.ircid].ircAlias, "You can use a named save with the block commands.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "list" and chatvars.words[2] == "saves" and chatvars.words[3] ~= nil and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		tmp.name = string.sub(chatvars.command, string.find(chatvars.command, "saves ") + 7)
		tmp.name = string.trim(tmp.name)
		tmp.pid = LookupPlayer(tmp.name)

		if tmp.pid == nil then
			tmp.pid = chatvars.playerid
			tmp.name = chatvars.playername
		end

		cursor,errorString = conn:execute("select * from prefabCopies where owner = " .. tmp.pid)
		row = cursor:fetch({}, "a")

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Saved prefabs created by " .. tmp.name .. ":[-]")

		if not row then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]None recorded.[-]")
		end

		while row do
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Name: " .. row.name .. " coords P1: " .. row.x1 .. " " .. row.y1 .. " " .. row.z1 .. " P2: " .. row.x2 .. " " .. row.y2 .. " " .. row.z2 .. "[-]")

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "mark <name> start")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "mark <name> end")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Mark two opposite corners of the area you wish to copy.  Move up or down between corners to add volume.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "mark" and (chatvars.words[3] == "start" or chatvars.words[3] == "end" or chatvars.words[3] == "p1" or chatvars.words[3] == "p2") and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
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
				conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")")
			else
				prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
				prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
				prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY -1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
				conn:execute("INSERT into prefabCopies (owner, name, x2, y2, z2) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. chatvars.intX .. "," .. chatvars.intY -1 .. "," .. chatvars.intZ .. ")")
			end
		else
			if chatvars.words[3] == "start" or chatvars.words[3] == "p1" then
				prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
				prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 = chatvars.intX
				prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 = chatvars.intY -1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 = chatvars.intZ

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " end[-]")
				conn:execute("UPDATE prefabCopies SET x1 = " .. chatvars.intX .. ", y1 = " .. chatvars.intY -1 .. ", z1 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'")
			else
				prefabCopies[chatvars.playerid .. chatvars.words[2]].owner = chatvars.playerid
				prefabCopies[chatvars.playerid .. chatvars.words[2]].name = chatvars.words[2]
				prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 = chatvars.intX
				prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 = chatvars.intY -1
				prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 = chatvars.intZ

				message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]Now move the opposite corner and use " .. server.commandPrefix .. "mark " .. chatvars.words[2] .. " start[-]")
				conn:execute("UPDATE prefabCopies SET x2 = " .. chatvars.intX .. ", y2 = " .. chatvars.intY -1 .. ", z2 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'")
			end
		end

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]When done save it with " .. server.commandPrefix .. "save " .. chatvars.words[2] .. "[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "save") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "save <name>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Now that you have marked out the area you want to copy, you can save it.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "save" and chatvars.words[2] ~= nil and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if not prefabCopies[chatvars.playerid .. chatvars.words[2]] then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked a prefab called " .. chatvars.words[2] .. ". Please do that first.[-]")
		else
			send("pexport " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].name)
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]You saved a prefab called " .. chatvars.words[2] .. ".[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "load") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "paste"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "load prefab <name> at <x> <y> <z> face <0-3>")
			irc_chat(players[chatvars.ircid].ircAlias, "Everything after the prefab name is optional and if not given, the stored coords and rotation will be used.")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Restore a saved prefab in place or place it somewhere else.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you provide coords and an optional rotation (default is 0 - north), you will make a new copy of the prefab at those coords.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you instead add here, it will load on your current position with optional rotation.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you only provide the name of the saved prefab, it will restore the prefab in place which replaces the original with the copy.")
				irc_chat(players[chatvars.ircid].ircAlias, "For perfect placement, start from a south corner.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "load" and chatvars.words[2] == "prefab" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if (chatvars.words[3] == nil) then
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]" .. server.commandPrefix .. "load prefab <name> at <x> <y> <z> face <0-3>[-]")
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

		send("prender " .. chatvars.playerid .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face)
		send("prender " .. tmp.prefab .. " " .. tmp.coords .. " " .. tmp.face)
		botman.lastBlockCommandOwner = chatvars.playerid

		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]A prefab called " .. tmp.prefab .. " should have spawned.  If it didn't either the prefab isn't called " .. tmp.prefab .. " or it doesn't exist.[-]")

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "list") or string.find(chatvars.command, "item"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "list (or " .. server.commandPrefix .. "li) <partial name of an item or block>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "List all items containing the text you are searching for.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if (chatvars.words[1] == "list" or chatvars.words[1] == "li") and chatvars.words[2] ~= nil and chatvars.words[3] == nil and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end
		
		playerListItems = chatvars.playerid
		send("li " .. chatvars.words[2])

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "move") or string.find(chatvars.command, "block") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prefab"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "move block <name of saved prefab> here")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "move block <name of saved prefab> <x> <y> <z>")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "move block <name of saved prefab> up (or down) <number>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Fills a saved block with air then renders it at the new position and updates the block's coordinates.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "move" and chatvars.words[2] == "block" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if prefabCopies[chatvars.playerid .. chatvars.words[3]] then
			-- first remove the original block by replacing it with air blocks
			send("pblock " .. 0 ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. " 0")
			botman.lastBlockCommandOwner = chatvars.playerid

			if chatvars.words[4] == "up" then
				prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number
				prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number
				conn:execute("UPDATE prefabCopies SET y1 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number .. ", y2 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[3]) .. "'")

				-- render the block at its new position
				send("pblock " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].blockName ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].rotation)
			end

			if chatvars.words[4] == "down" then
				prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 - chatvars.number
				prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 = prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 - chatvars.number
				conn:execute("UPDATE prefabCopies SET y1 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number .. ", y2 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[3]) .. "'")

				-- render the block at its new position
				send("pblock " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].blockName ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].rotation)
			end

			-- then update the xyz pairs so that you are standing on the lowest corner


			-- save the new coordinates
--				conn:execute("UPDATE prefabCopies SET x2 = " .. chatvars.intX .. ", y2 = " .. chatvars.intY -1 .. ", z2 = " .. chatvars.intZ .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'")

			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is unfinished :([-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "copy") or string.find(chatvars.command, "block") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prefab"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "copy block <name of saved prefab> here")
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "copy block <name of saved prefab> <x> <y> <z>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Renders a saved block at your position or the coordinates you specify")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "copy" and chatvars.words[2] == "block" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if prefabCopies[chatvars.playerid .. chatvars.words[3]] then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is unfinished :([-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rot") or (string.find(chatvars.command, "spin") or string.find(chatvars.command, "block") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prefab")))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "rotate (or " .. server.commandPrefix .. "spin) block <name of saved prefab>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Spins a block around its first XYZ")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "rotate" or chatvars.words[1] == "spin" and chatvars.words[2] == "block" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if prefabCopies[chatvars.playerid .. chatvars.words[3]] then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is unfinished :([-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "place") or string.find(chatvars.command, "door") or string.find(chatvars.command, "coppi") or string.find(chatvars.command, "prefab"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "place door block <block name or id> or prefab <name of saved prefab> named <name your door>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Creates a special door block infront of you.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "place" and chatvars.words[2] == "door" and (chatvars.words[3] == "block" or chatvars.words[3] == "prefab") and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.words[6] == nil then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]Missing name of door.[-]")
			message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]eg. " .. server.commandPrefix .. "place door " .. chatvars.words[3] .. " " .. chatvars.words[4] .. " named TheDoor[-]")
			botman.faultyChat = false
			return true
		end

		if chatvars.words[3] == "block" then
			tmp.block = chatvars.words[4]
			prefabCopies[chatvars.playerid .. "door" .. chatvars.words[6]] = {}
--			conn:execute("UPDATE prefabCopies SET y1 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 + chatvars.number .. ", y2 = " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 + chatvars.number .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[3]) .. "'")

			-- render the door
	--		send("pblock " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].blockName ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].z2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[3]].rotation)
		else
			if prefabCopies[chatvars.playerid .. chatvars.words[4]] then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is unfinished :([-]")
			else
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
			end
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "rot") or (string.find(chatvars.command, "spin") or string.find(chatvars.command, "block")))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "rotate (or " .. server.commandPrefix .. "spin) block <name of saved prefab>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Spins a block around its first XYZ")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "rotate" or chatvars.words[1] == "spin" and chatvars.words[2] == "block" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if prefabCopies[chatvars.playerid .. chatvars.words[3]] then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is unfinished :([-]")
		else
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]No saved block called " .. chatvars.words[3] .. "[-]")
		end

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "set") or string.find(chatvars.command, "mark") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set mark <optional player>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(players[chatvars.ircid].ircAlias, "If you add a player name it will record their current position instead.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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

			if tmp.pid ~= nil then
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
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set p1")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "set p2")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Temp store your current position for use in block commands which you use later. It is only stored in memory.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
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

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end		

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "erase") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "erase <optional number> (default 5)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Replace an area around you with air blocks.  Add a number to change the size.  Default is 5.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "erase" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is so restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		if chatvars.number == nil then
			chatvars.number = 5
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

		send("pexport " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. " " .. chatvars.playerid .. "bottemp")
		send("pblock air " .. chatvars.intX - chatvars.number .. " " .. chatvars.intX + chatvars.number .. " " .. chatvars.intY - chatvars.number .. " " .. chatvars.intY + chatvars.number .. " " .. chatvars.intZ - chatvars.number .. " " .. chatvars.intZ + chatvars.number .. " 0")
		botman.lastBlockCommandOwner = chatvars.playerid

		botman.faultyChat = false
		return true
	end

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

	if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "dig") or string.find(chatvars.command, "fill") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "coppi"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "dig (or fill) <optional number> (default 5)")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Dig a hole or fill a hole.  Default is 5.")
				irc_chat(players[chatvars.ircid].ircAlias, "This can also be used to make tunnels and walls.")
				irc_chat(players[chatvars.ircid].ircAlias, "When not digging or filling up or down, a compass direction is needed (north, south, east, west)")
				irc_chat(players[chatvars.ircid].ircAlias, "There are several optional parts, wide, block, tall, base and long.")
				irc_chat(players[chatvars.ircid].ircAlias, "Default block is air, base is at your feet and the others default to 5.")
				irc_chat(players[chatvars.ircid].ircAlias, "Examples:")
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "dig north wide 3 tall 3 long 100")
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "dig bedrock wide 1")				
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "dig up (makes a 5x5 room)")						
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "dig up (or room) wide 5 tall 10 (makes a 10x10 room)")										
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fill east base 70 wide 2 tall 10 long 50 block steelBlock")
				irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fill bedrock wide 2 block 1")								
				irc_chat(players[chatvars.ircid].ircAlias, "")						
				irc_chat(players[chatvars.ircid].ircAlias, "You can repeat the last command with /again and change direction with /again west")						
				irc_chat(players[chatvars.ircid].ircAlias, "")				
			end
		end
	end

	if chatvars.words[1] == "dig" or chatvars.words[1] == "fill" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 1) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		tmp.base = chatvars.intY - 1
		tmp.tall = chatvars.intY + 5
		tmp.block = "air"
		tmp.width = 5
		tmp.long = 5		

		for i=2,chatvars.wordCount,1 do
			if chatvars.words[i] == "wide" then
				tmp.width = chatvars.words[i+1]
				tmp.tall = tmp.width
			end
			
			if chatvars.words[i] == "replace" then
				tmp.newblock = chatvars.words[i+1]
			end			

			if chatvars.words[i] == "block" then
				tmp.block = chatvars.words[i+1]
			end

			if chatvars.words[i] == "tall" or chatvars.words[i] == "deep" then
				tmp.tall = chatvars.words[i+1]
			end

			if chatvars.words[i] == "base" then
				tmp.base = chatvars.words[i+1]
			end

			if chatvars.words[i] == "long" then
				tmp.long = chatvars.words[i+1]
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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				if tmp.newblock then
				--prepblock <block_to_be_replaced> <block_name> <x1> <x2> <y1> <y2> <z1> <z2> <rot>
					send("prepblock " .. tmp.newblock .. " air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")				
				else
					send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				end
			else
				if tmp.newblock then
					send("prepblock " .. tmp.newblock .. " " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")				
				else			
					send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
				end
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

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

			send("pexport " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " " .. chatvars.playerid .. "bottemp")

			if chatvars.words[1] == "dig" then
				send("pblock air " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			else
				send("pblock " .. tmp.block .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].x2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].y2 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z1 .. " " .. prefabCopies[chatvars.playerid .. "bottemp"].z2 .. " 0")
			end

			botman.lastBlockCommandOwner = chatvars.playerid

			botman.faultyChat = false
			return true
		end
	end
	
	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "fix") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "bed"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fix bedrock <distance>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "You can replace the bedrock layer below you up to <distance> away from your position.")
				irc_chat(players[chatvars.ircid].ircAlias, "You only need to be over the area to be fixed.  No other layers are touched.")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "fix" and chatvars.words[2] == "bedrock" and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
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

		send("pblock 12 " .. tmp.x1 .. " " .. tmp.x2 .. " " .. tmp.y1 .. " " .. tmp.y2 .. " " .. tmp.z1 .. " " .. tmp.z2 .. " 0")		
		
		botman.faultyChat = false
		return true
	end	

	if (debug) then dbug("debug coppi line " .. debugger.getinfo(1).currentline) end

		if chatvars.showHelp and not skipHelp then
		if (chatvars.words[1] == "help" and (string.find(chatvars.command, "block") or string.find(chatvars.command, "prefab") or string.find(chatvars.command, "copy"))) or chatvars.words[1] ~= "help" then
			irc_chat(players[chatvars.ircid].ircAlias, server.commandPrefix .. "fill <name of saved prefab> <block ID> face <north, south, east, west or n, s, e, w>")

			if not shortHelp then
				irc_chat(players[chatvars.ircid].ircAlias, "Now that you have marked out the area you replace every block with 1 type of block.")
				irc_chat(players[chatvars.ircid].ircAlias, "eg. " .. server.commandPrefix .. "fill wall 8 south (default facing is north.  8 is the block id for sand.)")
				irc_chat(players[chatvars.ircid].ircAlias, "")
			end
		end
	end

	if chatvars.words[1] == "fill" and chatvars.words[2] ~= nil and (chatvars.playerid ~= 0) then
		if (chatvars.playername ~= "Server") then
			if (chatvars.accessLevel > 2) then
				message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]This command is restricted[-]")
				botman.faultyChat = false
				return true
			end
		end

		tmp.face = "0"
		tmp.block = chatvars.words[3]

		if chatvars.words[5] == "east" or chatvars.words[5] == "e" then tmp.face = 1 end
		if chatvars.words[5] == "south" or chatvars.words[5] == "s" then tmp.face = 2 end
		if chatvars.words[5] == "west" or chatvars.words[5] == "w" then tmp.face = 3 end

		if not prefabCopies[chatvars.playerid .. chatvars.words[2]] then
			message("pm " .. chatvars.playerid .. " [" .. server.warnColour .. "]You haven't marked a prefab called " .. chatvars.words[2] .. ". Please do that first.[-]")
		else
			prefabCopies[chatvars.playerid .. chatvars.words[2]].blockName = tmp.block
			prefabCopies[chatvars.playerid .. chatvars.words[2]].rotation = tmp.face
			send("pblock " .. tmp.block ..  " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 .. " " .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 .. " " .. tmp.face)
			botman.lastBlockCommandOwner = chatvars.playerid
			-- save the block to the database
			conn:execute("INSERT into prefabCopies (owner, name, x1, y1, z1, x2, y2, z2) VALUES (" .. chatvars.playerid .. ",'" .. escape(chatvars.words[2]) .. "'," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x1 .. "," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y1 .. "," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z1 .. "," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].x2 .. "," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].y2 .. "," .. prefabCopies[chatvars.playerid .. chatvars.words[2]].z2 .. ")")
			conn:execute("UPDATE prefabCopies SET blockName = '" .. escape(tmp.block) .. "', rotation = " .. tmp.face .. " WHERE owner = " .. chatvars.playerid .. " AND name = '" .. escape(chatvars.words[2]) .. "'")
		end

		botman.faultyChat = false
		return true
	end

if debug then dbug("debug coppi end") end

end
