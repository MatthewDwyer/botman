--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function memTrigger(line)
	if botman.botDisabled then
		return
	end

	local time, fps, heap, heapMax, chunks, cgo, ply, zom, ent, items

	if (string.find(line, "Heap:")) then
		time = string.sub(line, string.find(line, "Time:") + 6, string.find(line, "FPS:") - 3)
		fps = tonumber(string.sub(line, string.find(line, "FPS:") + 5, string.find(line, "Heap:") - 2))
		heap = string.sub(line, string.find(line, "Heap:") + 6, string.find(line, "Max:") - 4)
		heapMax = string.sub(line, string.find(line, "Max:") + 5, string.find(line, "Chunks:") - 4)
		chunks = string.sub(line, string.find(line, "Chunks:") + 8, string.find(line, "CGO:") - 2)
		cgo = string.sub(line, string.find(line, "CGO:") + 5, string.find(line, "Ply:") - 2)
		ply = string.sub(line, string.find(line, "Ply:") + 5, string.find(line, "Zom:") - 2)
		zom = string.sub(line, string.find(line, "Zom:") + 5, string.find(line, "Ent:") - 2)
		ent = string.sub(line, string.find(line, "Ent:") + 5, string.find(line, "Items:") - 2)
		items = string.sub(line, string.find(line, "Items:") + 7, string.find(line, "CO:") - 2)

		server.fps = fps
		conn:execute("INSERT INTO performance (serverdate, gametime, fps, heap, heapMax, chunks, cgo, players, zombies, entities, items) VALUES ('" .. botman.serverTime .. "'," .. time .. "," .. fps .. "," .. heap .. "," .. heapMax .. "," .. chunks .. "," .. cgo .. "," .. ply .. "," .. zom .. ",'" .. ent .. "'," .. items .. ")")
	end
end
