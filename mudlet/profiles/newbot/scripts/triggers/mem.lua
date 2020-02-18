--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2020  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function memTrigger(line)
	if botman.botDisabled then
		return
	end

	local time, fps, heap, heapMax, chunks, cgo, ply, zom, ent, items, k, v

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
		server.fps = tonumber(fps)

		botman.playersOnline = 0
		ply = string.trim(ply)

		server.uptime = math.floor(time * 60)
		botman.lastUptimeRead = os.time()

		if botman.dbConnected then
			conn:execute("INSERT INTO performance (serverdate, gametime, fps, heap, heapMax, chunks, cgo, players, zombies, entities, items) VALUES ('" .. botman.serverTime .. "'," .. time .. "," .. fps .. "," .. heap .. "," .. heapMax .. "," .. chunks .. "," .. cgo .. "," .. ply .. "," .. zom .. ",'" .. ent .. "'," .. items .. ")")
		end

		if tonumber(ply) >= 0 then
			botman.playersOnline = tonumber(ply)
		end

		if botman.getMetrics then
			if metrics == nil then
				metrics = {} -- Welcome to the metrics Neo
				metrics.pass = 1
			end

			if metrics.pass == 1 then
				metrics.pass = 2
				metrics.startTime = os.time()
				metrics.endTime = metrics.startTime
				metrics.commands = 0
				metrics.commandLag = 0
				metrics.errors = 0
				metrics.telnetLines = 0
				metrics.playersOnlineStart = botman.playersOnline
				metrics.playersOnlineEnd = botman.playersOnline

				if botman.getFullMetrics then
					metrics.playersStart = {}

					for k,v in pairs(igplayers) do
						metrics.playersStart[k] = {}
						metrics.playersStart[k].steam = k
						metrics.playersStart[k].name = v.name
						metrics.playersStart[k].x = v.xPos
						metrics.playersStart[k].y = v.yPos
						metrics.playersStart[k].z = v.zPos
						metrics.playersStart[k].region = v.region
						metrics.playersStart[k].ping = v.ping
						metrics.playersStart[k].keystones = players[k].keystones
						metrics.playersStart[k].location = players[k].inLocation
					end
				end

				metrics.performanceAtStart = fps .. " | " .. heap .. " | " .. heapMax .. " | " .. chunks .. " | " .. cgo .. " | " .. ply .. " | " .. zom .. " | " .. ent .. " | " .. items
				metrics.performanceAtEnd = ""
			else
				metrics.pass = 1
				metrics.endTime = os.time()
				metrics.performanceAtEnd = fps .. " | " .. heap .. " | " .. heapMax .. " | " .. chunks .. " | " .. cgo .. " | " .. ply .. " | " .. zom .. " | " .. ent .. " | " .. items

				metrics.playersOnlineEnd = botman.playersOnline

				if botman.getFullMetrics then
					metrics.playersEnd = {}

					for k,v in pairs(igplayers) do
						metrics.playersEnd[k] = {}
						metrics.playersEnd[k].steam = k
						metrics.playersEnd[k].name = v.name
						metrics.playersEnd[k].x = v.xPos
						metrics.playersEnd[k].y = v.yPos
						metrics.playersEnd[k].z = v.zPos
						metrics.playersEnd[k].region = v.region
						metrics.playersEnd[k].ping = v.ping
						metrics.playersEnd[k].keystones = players[k].keystones
						metrics.playersEnd[k].location = players[k].inLocation
					end
				end

				-- report it to the alerts channel
				irc_chat(metrics.reportTo, "---")
				irc_chat(metrics.reportTo, "Metrics report")
				irc_chat(metrics.reportTo, "Runtime: " .. metrics.endTime - metrics.startTime .. " seconds")
				irc_chat(metrics.reportTo, "Commands run: " .. metrics.commands)
				irc_chat(metrics.reportTo, "Telnet lines processed: " .. metrics.telnetLines)
				irc_chat(metrics.reportTo, "Telnet error lines seen: " .. metrics.errors)
				irc_chat(metrics.reportTo, "Telnet command lag: " .. metrics.commandLag)
				irc_chat(metrics.reportTo, "Performance: FPS  |  HEAP  |  HEAPMAX  |  CHUNKS  |  CGO  |  PLAYERS  |  ZOMBIES  |  ENTITIES  |  ITEMS")
				irc_chat(metrics.reportTo, "Performance At Start: " .. metrics.performanceAtStart)
				irc_chat(metrics.reportTo, "Performance At End: " .. metrics.performanceAtEnd)

				irc_chat(metrics.reportTo, ".")
				irc_chat(metrics.reportTo, "Players online at start: " .. metrics.playersOnlineStart)

				if botman.getFullMetrics then
					for k,v in pairs(metrics.playersStart) do
						irc_chat(metrics.reportTo, "Player: " .. v.steam .. " " .. v.name .. " ping: " .. v.ping)
						irc_chat(metrics.reportTo, "XYZ: " .. v.x .. " " .. v.y .. " " .. v.z .. " region: " .. v.region)
						irc_chat(metrics.reportTo, "In location: " .. v.location)
						irc_chat(metrics.reportTo, "Claims: " .. v.keystones)
						irc_chat(metrics.reportTo, ".")
					end
				end

				irc_chat(metrics.reportTo, "Players online at end: " .. metrics.playersOnlineEnd)

				if botman.getFullMetrics then
					for k,v in pairs(metrics.playersEnd) do
						irc_chat(metrics.reportTo, "Player: " .. v.steam .. " " .. v.name .. " ping: " .. v.ping)
						irc_chat(metrics.reportTo, "XYZ: " .. v.x .. " " .. v.y .. " " .. v.z .. " region: " .. v.region)
						irc_chat(metrics.reportTo, "In location: " .. v.location)
						irc_chat(metrics.reportTo, "Claims: " .. v.keystones)
						irc_chat(metrics.reportTo, ".")
						irc_chat(metrics.reportTo, "To stop reporting type stop report")
						irc_chat(metrics.reportTo, ".")
					end
				end

				-- reset metrics for next pass
				metrics.performanceAtStart = metrics.performanceAtEnd
				metrics.performanceAtEnd = ""
				metrics.playersStart = metrics.playersEnd
				metrics.playersEnd = {}
				metrics.startTime = os.time()
				metrics.endTime = metrics.startTime
				metrics.commands = 0
				metrics.errors = 0
				metrics.telnetLines = 0
				metrics.commandLag = 0
				metrics.playersOnlineStart = botman.playersOnline
				metrics.playersOnlineEnd = botman.playersOnline
			end
		end
	end
end
