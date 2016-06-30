--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2015  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function gameTickCountTrigger(line)
if botDisabled then
	return
end

local diff, days, hours

-- grab the tick counter
test = string.sub(line, string.find(line, ":") + 7, string.find(line, " INF"))
gameTick = tonumber(test)

if nextRebootTest ~= nil and os.time() < nextRebootTest then
	return
end

if gameTick > 0 then
	server.uptime = gameTick
else
	server.uptime = os.time() - botStarted
end

if gameTick < 0 and server.scheduledRestart == false and server.allowReboot == true then
	gmsg("/reboot server in 5 minutes", 0)
	message("say [" .. server.chatColour .. "]A fault has been detected. A reboot should fix it.[-]")
end

diff = gameTick
days = math.floor(diff / 86400)

if (days > 0) then
	diff = diff - (days * 86400)
end

hours = math.floor(diff / 3600)

if tonumber(hours) >= tonumber(server.maxServerUptime) and server.scheduledRestart == false and server.allowReboot == true then
	message("say [" .. server.chatColour .. "]The server will reboot soon to keep it running well.[-]")
	gmsg("/reboot in 15 minutes", 0)
end
end
