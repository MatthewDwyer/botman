--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

-- Support for UberFox's UberBot Extended API

-- FAPGD SUCCESS IdCount=2;IdList='76561197983251951|76561198190468434'

--[[
 ubex_fapgd  => check if any player is over a specific ground dist
 ubex_iea  => check if an entity (or many) is alive (exists)
 ubex_opt  => change UberBotEx options
 ubex_pgd  => get ground dist from a player (entity id or name)
 ubex_sexyz  => spawn an entity at a given x y z
 ubex_tele  => teleport a player to a given location
 ubex_ubexv  => get the version etc of the UberBotEx
 ubex_keiz  => kill all entities within a Zone
 
*** Command: ubex_keiz ***
Usage:
   ubex_keiz <uniqueId> <x> <y> <z> <x1> <y1> <z1> <killMask> <killEntityTypes> <notKillEntityTypes>

*** Command: ubex_fapgd ***
Check if any player is over a specific ground dist
Usage:
   ubex_fapgd <dist>

*** Command: ubex_iea ***
Usage:
   ubex_iea <entityId>
   ubex_iea <entityId;entityId;entityId;...>

*** Command: ubex_opt ***
Usage:
   ubex_opt <uniqueId> <option>
   ubex_opt <uniqueId> <option> <value>
(Options: hidecmds, physics)

*** Command: ubex_pgd ***
Find out the distance from a player to the ground
Usage:
   ubex_pgd <name / entity id>

*** Command: ubex_sexyz ***
Usage:
   ubex_sexy <entityName> <x> <y> <z> <uniqueId>

*** Command: ubex_tele ***
Usage:
  1. ubex_tele <uniqueId> <dist> <steam id / player name / entity id> <x> <y> <z>
  2. ubex_tele <uniqueId> <dist> <steam id / player name / entity id> <target steam id / player name 
/ entity id>
  3. ubex_tele <uniqueId> <dist> <inc x> <inc y> <inc z>
1. Teleports the player given by his SteamID, player name or entity id (as given by e.g. "lpi")
   to the specified location. Use y = -1 to spawn on ground.
2. As 1, but destination given by another player which has to be online
3. Teleport the local player to the position calculated by his current position and the given 
offsets(This is basically same as Alloc's tele but with added anti-cheat protection)
Day 447, 22:41 
--]]
