--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function sleep(s)
	dbug("sleeping " .. s)

	local ntime = os.time() + s
	repeat until os.time() > ntime
end


function processConnectQueue(steam)
	local cursor, errorString, row

	cursor,errorString = conn:execute("SELECT * FROM connectQueue WHERE steam = " .. steam .. "  ORDER BY id")

	if cursor then
		row = cursor:fetch({}, "a")

		while row do
			if string.sub(row.command, 1, 3) == "pm " or string.sub(row.command, 1, 3) == "say" then
				message(row.command)
			else
				send(row.command)
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			conn:execute("UPDATE connectQueue SET processed = 1 WHERE id = " .. row.id)
			row = cursor:fetch(row, "a")
		end

		conn:execute("DELETE FROM connectQueue WHERE processed = 1")
	end
end


function checkVACBan(steam)
	-- while there is a more efficient way to do this using the Steam API, this way works without all the extra stuff required to use the API.
	local file, ln, fileStr

	fileStr = homedir .. "/temp/steamrep_" .. steam .. ".txt"

	file = io.open(fileStr, "r")
	for ln in file:lines() do
		if string.find(ln, "vacbanned") then
			if string.find(ln, "<span id=\"vacbanned\"><span class=\"a02\">Banned</span></span>") then
				io.close(file)
				tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])

				if players[steam] then
					players[steam].VACBanned = true
					if botman.dbConnected then conn:execute("UPDATE players SET VACBanned=1 WHERE steam = " .. steam) end

					if accessLevel(steam) > 2 and not whitelist[steam] then
						alertAdmins("Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircAlerts, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
						irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has one or more VAC bans on record.")
					end
				else
					alertAdmins("Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircAlerts, "Player " .. steam .. " has one or more VAC bans on record.")
					irc_chat(server.ircMain, "Player " .. steam .. " has one or more VAC bans on record.")
				end

				if server.banVACBannedPlayers and not whitelist[steam] and accessLevel(steam) > 2 then
					banPlayer(steam, "10 years", "You have a VAC ban")
				end

				return true
			else
				io.close(file)
				tempTimer( 2, [[ os.remove("]] .. fileStr .. [[")]])

				players[steam].VACBanned = false
				return false
			end
		end
	end
end


function reloadCode()
	tempTimer(5, [[ reloadStartup() ]] )

	dofile(homedir .. "/scripts/reload_bot_scripts.lua")
	reloadBotScripts(true)
end


function reloadStartup()
	dofile(homedir .. "/scripts/startup_bot.lua")
end


function onSysExit()
	saveWindowLayout()
end


function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end


function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end


function readAPI()
	if isFile(homedir .. "/api.ini") then
		dofile(homedir .. "/api.ini")
	end
end


function writeAPI()
	local file

	-- first delete the file
	os.remove(homedir .. "/api.ini")

	-- now build a new one
	file = io.open(homedir .. "/api.ini", "a")

	if serverAPI ~= nil then
		file:write("serverAPI=\"" .. serverAPI .. "\"\n")
	end

	if botmanAPI ~= nil then
		file:write("botmanAPI=\"" .. botmanAPI .. "\"\n")
	end

	file:close()
end


function readServerVote(steam)
	local file, ln, url, result

	file = io.open(homedir .. "/temp/voteCheck.txt", "r")

	for ln in file:lines() do
		if ln == "0" then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Reward?  For what?  You haven't voted today!  You can claim your reward after voting.[-]")
			file:close()

			return
		end

		if ln == "1" then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Thanks for voting for us!  Your reward should spawn beside you.[-]")
			send("se " .. steam .. " " .. botman.sc_General)
			file:close()

			-- claim the vote
			url = "https://7daystodie-servers.com/api/?action=post&object=votes&element=claim&key=" .. serverAPI .. "&steamid=" .. steam
			os.remove(homedir .. "/temp/voteClaim.txt")
			downloadFile(homedir .. "/temp/voteClaim.txt", url)

			return
		end

		if ln == "2" then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Thanks for voting today.  You have already claimed your reward.  Vote for us tomorrow and you can claim another reward then.[-]")
			file:close()

			return
		end
	end

	file:close()
end


function checkServerVote(steam)
	local url

	if serverAPI ~= nil then
		url = "https://7daystodie-servers.com/api/?object=votes&element=claim&key=" .. serverAPI .. "&steamid=" .. steam

		os.remove(homedir .. "/temp/voteCheck.txt")
		downloadFile(homedir .. "/temp/voteCheck.txt", url)

		tempTimer( 5, [[ readServerVote("]] .. steam .. [[") ]] )
	end
end


function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end


function restartBot()
	savePlayers()
	closeMudlet()
end


function isServerHardcore(playerid)
	if server.hardcore and accessLevel(playerid) > 2 then
		return true
	else
		return false
	end
end


function readBotmanINI()
	if isFile(homedir .. "/botman.ini") then
		dofile(homedir .. "/botman.ini")
	end
end


function writeBotmanINI()
	local file

	-- first delete the file
	os.remove(homedir .. "/botman.ini")

	-- then build it
	file = io.open(homedir .. "/botman.ini", "a")

	-- server data
	if server.botOwner then file:write("botOwner=\"" .. server.botOwner .. "\"\n") end
	if server.serverName then file:write("botOwner=\"" .. server.serverName .. "\"\n") end
	if server.accessLevelOverride then file:write("server.accessLevelOverride=" .. server.accessLevelOverride .. "\n") end
	if server.alertColour then file:write("server.alertColour=\"" .. server.alertColour .. "\"\n") end
	if server.alertSpending ~= nil then file:write("server.alertSpending=\"" .. trueFalse(server.alertSpending) .. "\"\n") end
	if server.allowBank ~= nil then file:write("server.allowBank=\"" .. trueFalse(server.allowBank) .. "\"\n") end
	if server.allowBotRestarts ~= nil then file:write("server.allowBotRestarts=\"" .. trueFalse(server.allowBotRestarts) .. "\"\n") end
	if server.allowGarbageNames ~= nil then file:write("server.allowGarbageNames=\"" .. trueFalse(server.allowGarbageNames) .. "\"\n") end
	if server.allowGimme ~= nil then file:write("server.allowGimme=\"" .. trueFalse(server.allowGimme) .. "\"\n") end
	if server.allowHomeTeleport ~= nil then file:write("server.allowHomeTeleport=\"" .. trueFalse(server.allowHomeTeleport) .. "\"\n") end
	if server.allowLottery ~= nil then file:write("server.allowLottery=\"" .. trueFalse(server.allowLottery) .. "\"\n") end
	if server.allowNumericNames ~= nil then file:write("server.allowNumericNames=\"" .. trueFalse(server.allowNumericNames) .. "\"\n") end
	if server.allowOverstacking ~= nil then file:write("server.allowOverstacking=\"" .. trueFalse(server.allowOverstacking) .. "\"\n") end
	if server.allowPackTeleport ~= nil then file:write("server.allowPackTeleport=\"" .. trueFalse(server.allowPackTeleport) .. "\"\n") end
	if server.allowPhysics ~= nil then file:write("server.allowPhysics=\"" .. trueFalse(server.allowPhysics) .. "\"\n") end
	if server.allowPlayerToPlayerTeleporting ~= nil then file:write("server.allowPlayerToPlayerTeleporting=\"" .. trueFalse(server.allowPlayerToPlayerTeleporting) .. "\"\n") end
	if server.allowPlayerVoteTopics ~= nil then file:write("server.allowPlayerVoteTopics=\"" .. trueFalse(server.allowPlayerVoteTopics) .. "\"\n") end
	if server.allowProxies ~= nil then file:write("server.allowProxies=\"" .. trueFalse(server.allowProxies) .. "\"\n") end
	if server.allowRapidRelogging ~= nil then file:write("server.allowRapidRelogging=\"" .. trueFalse(server.allowRapidRelogging) .. "\"\n") end
	if server.allowReboot ~= nil then file:write("server.allowReboot=\"" .. trueFalse(server.allowReboot) .. "\"\n") end
	if server.allowReturns ~= nil then file:write("server.allowReturns=\"" .. trueFalse(server.allowReturns) .. "\"\n") end
	if server.allowShop ~= nil then file:write("server.allowShop=\"" .. trueFalse(server.allowShop) .. "\"\n") end
	if server.allowStuckTeleport ~= nil then file:write("server.allowStuckTeleport=\"" .. trueFalse(server.allowStuckTeleport) .. "\"\n") end
	if server.allowTeleporting ~= nil then file:write("server.allowTeleporting=\"" .. trueFalse(server.allowTeleporting) .. "\"\n") end
	if server.allowVoting ~= nil then file:write("server.allowVoting=\"" .. trueFalse(server.allowVoting) .. "\"\n") end
	if server.allowWaypoints ~= nil then file:write("server.allowWaypoints=\"" .. trueFalse(server.allowWaypoints) .. "\"\n") end
	if server.announceTeleports ~= nil then file:write("server.announceTeleports=\"" .. trueFalse(server.announceTeleports) .. "\"\n") end
	if server.bailCost then file:write("server.bailCost=" .. server.bailCost .. "\n") end
	if server.baseCooldown then file:write("server.baseCooldown=" .. server.baseCooldown .. "\n") end
	if server.baseCost then file:write("server.baseCost=" .. server.baseCost .. "\n") end
	if server.baseSize then file:write("server.baseSize=" .. server.baseSize .. "\n") end
	if server.blacklistResponse then file:write("server.blacklistResponse=\"" .. server.blacklistResponse .. "\"\n") end
	if server.blacklistCountries then file:write("server.blacklistCountries=\"" .. server.blacklistCountries .. "\"\n") end
	if server.botName then file:write("server.botName=\"" .. server.botName .. "\"\n") end
	if server.botRestartHour then file:write("server.botRestartHour=" .. server.botRestartHour .. "\n") end
	if server.botsIP then file:write("server.botsIP=\"" .. server.botsIP .. "\"\n") end
	if server.CBSMFriendly ~= nil then file:write("server.CBSMFriendly=\"" .. trueFalse(server.CBSMFriendly) .. "\"\n") end
	if server.chatColour then file:write("server.chatColour=\"" .. server.chatColour .. "\"\n") end
	if server.chatColourAdmin then file:write("server.chatColourAdmin=\"" .. server.chatColourAdmin .. "\"\n") end
	if server.chatColourDonor then file:write("server.chatColourDonor=\"" .. server.chatColourDonor .. "\"\n") end
	if server.chatColourMod then file:write("server.chatColourMod=\"" .. server.chatColourMod .. "\"\n") end
	if server.chatColourNewPlayer then file:write("server.chatColourNewPlayer=\"" .. server.chatColourNewPlayer .. "\"\n") end
	if server.chatColourOwner then file:write("server.chatColourOwner=\"" .. server.chatColourOwner .. "\"\n") end
	if server.chatColourPlayer then file:write("server.chatColourPlayer=\"" .. server.chatColourPlayer .. "\"\n") end
	if server.chatColourPrisoner then file:write("server.chatColourPrisoner=\"" .. server.chatColourPrisoner .. "\"\n") end
	if server.chatlogPath then file:write("server.chatlogPath=\"" .. server.chatlogPath .. "\"\n") end
	if server.commandPrefix then file:write("server.commandPrefix=\"" .. server.commandPrefix .. "\"\n") end
	if server.disableBaseProtection ~= nil then file:write("server.disableBaseProtection=\"" .. trueFalse(server.disableBaseProtection) .. "\"\n") end
	if server.disableTPinPVP ~= nil then file:write("server.disableTPinPVP=\"" .. trueFalse(server.disableTPinPVP) .. "\"\n") end
	if server.disableWatchAlerts ~= nil then file:write("server.disableWatchAlerts=\"" .. trueFalse(server.disableWatchAlerts) .. "\"\n") end
	if server.enableRegionPM then file:write("server.enableRegionPM=\"" .. trueFalse(server.enableRegionPM) .. "\"\n") end
	if server.feralRebootDelay then file:write("server.feralRebootDelay=" .. server.feralRebootDelay .. "\n") end
	if server.gameType then file:write("server.gameType=\"" .. server.gameType .. "\"\n") end
	if server.GBLBanThreshold then file:write("server.GBLBanThreshold=" .. server.GBLBanThreshold .. "\n") end
	if server.gimmePeace ~= nil then file:write("server.gimmePeace=\"" .. trueFalse(server.gimmePeace) .. "\"\n") end
	if server.gimmeZombies ~= nil then file:write("server.gimmeZombies=\"" .. trueFalse(server.gimmeZombies) .. "\"\n") end
	if server.hackerTPDetection ~= nil then file:write("server.hackerTPDetection=\"" .. trueFalse(server.hackerTPDetection) .. "\"\n") end
	if server.hardcore ~= nil then file:write("server.hardcore=\"" .. trueFalse(server.hardcore) .. "\"\n") end
	if server.hideCommands ~= nil then file:write("server.hideCommands=\"" .. trueFalse(server.hideCommands) .. "\"\n") end
	if server.idleKick ~= nil then file:write("server.idleKick=\"" .. trueFalse(server.idleKick) .. "\"\n") end
	if server.IP then file:write("server.IP=\"" .. server.IP .. "\"\n") end
	if server.ircAlerts then file:write("server.ircAlerts=\"" .. server.ircAlerts .. "\"\n") end
	if server.ircBotName then file:write("server.ircBotName=\"" .. server.ircBotName .. "\"\n") end
	if server.ircMain then file:write("server.ircChannel=\"" .. server.ircMain .. "\"\n") end
	if server.ircPort then file:write("server.ircPort=" .. server.ircPort .. "\n") end
	if server.ircPrivate ~= nil then file:write("server.ircPrivate=\"" .. trueFalse(server.ircPrivate) .. "\"\n") end
	if server.ircServer then file:write("server.ircServer=\"" .. server.ircServer .. "\"\n") end
	if server.ircTracker then file:write("server.ircTracker=\"" .. server.ircTracker .. "\"\n") end
	if server.ircWatch then file:write("server.ircWatch=\"" .. server.ircWatch .. "\"\n") end
	if server.lottery then file:write("server.lottery=" .. server.lottery .. "\n") end
	if server.lotteryMultiplier then file:write("server.lotteryMultiplier=" .. server.lotteryMultiplier .. "\n") end
	if server.mapSize then file:write("server.mapSize=" .. server.mapSize .. "\n") end
	if server.maxPrisonTime then file:write("server.maxPrisonTime=" .. server.maxPrisonTime .. "\n") end
	if server.maxServerUptime then file:write("server.maxServerUptime=" .. server.maxServerUptime .. "\n") end
	if server.maxWaypoints then file:write("server.maxWaypoints=" .. server.maxWaypoints .. "\n") end
	if server.moneyName then file:write("server.moneyName=\"" .. server.moneyName .. "\"\n") end
	if server.moneyPlural then file:write("server.moneyPlural=\"" .. server.moneyPlural .. "\"\n") end
	if server.MOTD then file:write("server.MOTD=\"" .. server.MOTD .. "\"\n") end
	if server.newPlayerTimer then file:write("server.newPlayerTimer=" .. server.newPlayerTimer .. "\n") end
	if server.northeastZone then file:write("server.northeastZone=\"" .. server.northeastZone .. "\"\n") end
	if server.northwestZone then file:write("server.northwestZone=\"" .. server.northwestZone .. "\"\n") end
	if server.overstackThreshold then file:write("server.overstackThreshold=" .. server.overstackThreshold .. "\n") end
	if server.packCooldown then file:write("server.packCooldown=" .. server.packCooldown .. "\n") end
	if server.packCost then file:write("server.packCost=" .. server.packCost .. "\n") end
	if server.perMinutePayRate then file:write("server.perMinutePayRate=" .. server.perMinutePayRate .. "\n") end
	if server.pingKick then file:write("server.pingKick=" .. server.pingKick .. "\n") end
	if server.playersCanFly ~= nil then file:write("server.playersCanFly=\"" .. trueFalse(server.playersCanFly) .. "\"\n") end
	if server.playerTeleportDelay then file:write("server.playerTeleportDelay=" .. server.playerTeleportDelay .. "\n") end
	if server.protectionMaxDays then file:write("server.protectionMaxDays=" .. server.protectionMaxDays .. "\n") end
	if server.pvpAllowProtect ~= nil then file:write("server.pvpAllowProtect=\"" .. trueFalse(server.pvpAllowProtect) .. "\"\n") end
	if server.pvpIgnoreFriendlyKills ~= nil then file:write("server.pvpIgnoreFriendlyKills=\"" .. trueFalse(server.pvpIgnoreFriendlyKills) .. "\"\n") end
	if server.pvpTeleportCooldown then file:write("server.pvpTeleportCooldown=" .. server.pvpTeleportCooldown .. "\n") end
	if server.rebootHour then file:write("server.rebootHour=" .. server.rebootHour .. "\n") end
	if server.rebootMinute then file:write("server.rebootMinute=" .. server.rebootMinute .. "\n") end
	if server.reservedSlots then file:write("server.reservedSlots=" .. server.reservedSlots .. "\n") end
	if server.restrictIRC ~= nil then file:write("server.restrictIRC=\"" .. trueFalse(server.restrictIRC) .. "\"\n") end
	if server.rules then file:write("server.rules=\"" .. server.rules .. "\"\n") end
	if server.scanEntities ~= nil then file:write("server.scanEntities=\"" .. trueFalse(server.scanEntities) .. "\"\n") end
	if server.scanErrors ~= nil then file:write("server.scanErrors=\"" .. trueFalse(server.scanErrors) .. "\"\n") end
	if server.scanNoclip ~= nil then file:write("server.scanNoclip=\"" .. trueFalse(server.scanNoclip) .. "\"\n") end
	if server.scanZombies ~= nil then file:write("server.scanZombies=\"" .. trueFalse(server.scanZombies) .. "\"\n") end
	if server.serverGroup then file:write("server.serverGroup=\"" .. server.serverGroup .. "\"\n") end
	if server.shopCloseHour then file:write("server.shopCloseHour=" .. server.shopCloseHour .. "\n") end
	if server.shopCountdown then file:write("server.shopCountdown=" .. server.shopCountdown .. "\n") end
	if server.shopOpenHour then file:write("server.shopOpenHour=" .. server.shopOpenHour .. "\n") end
	if server.southeastZone then file:write("server.southeastZone=\"" .. server.southeastZone .. "\"\n") end
	if server.southwestZone then file:write("server.southwestZone=\"" .. server.southwestZone .. "\"\n") end
	if server.swearCash then file:write("server.swearCash=" .. server.swearCash .. "\n") end
	if server.swearFine then file:write("server.swearFine=" .. server.swearFine .. "\n") end
	if server.swearJar ~= nil then file:write("server.swearJar=\"" .. trueFalse(server.swearJar) .. "\"\n") end
	if server.teleportCost then file:write("server.teleportCost=" .. server.teleportCost .. "\n") end
	if server.teleportPublicCooldown then file:write("server.teleportPublicCooldown=" .. server.teleportPublicCooldown .. "\n") end
	if server.teleportPublicCost then file:write("server.teleportPublicCost=" .. server.teleportPublicCost .. "\n") end
	if server.telnetPort then file:write("server.telnetPort=" .. server.telnetPort .. "\n") end
	if server.trackingKeepDays then file:write("server.trackingKeepDays=" .. server.trackingKeepDays .. "\n") end
	if server.updateBot ~= nil then file:write("server.updateBot=\"" .. trueFalse(server.updateBot) .. "\"\n") end
	if server.updateBranch then file:write("server.updateBranch=\"" .. server.updateBranch .. "\"\n") end
	if server.warnColour then file:write("server.warnColour=\"" .. server.warnColour .. "\"\n") end
	if server.waypointCooldown then file:write("server.waypointCooldown=" .. server.waypointCooldown .. "\n") end
	if server.waypointCost then file:write("server.waypointCost=" .. server.waypointCost .. "\n") end
	if server.waypointCreateCost then file:write("server.waypointCreateCost=" .. server.waypointCreateCost .. "\n") end
	if server.waypointsPublic ~= nil then file:write("server.waypointsPublic=\"" .. trueFalse(server.waypointsPublic) .. "\"\n") end
	if server.whitelistCountries then file:write("server.whitelistCountries=\"" .. server.whitelistCountries .. "\"\n") end
	if server.zombieKillReward then file:write("server.zombieKillReward=" .. server.zombieKillReward .. "\n") end

	file:close()
end


function runTimedEvents()
	local cursor, errorString, rows, row

	if botman.dbConnected then
		-- make sure the announcements event exists
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE timer = 'announcements'")
		row = cursor:fetch({}, "a")

		if not row then
			conn:execute("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('announcements', '60', CURRENT_TIMESTAMP, '0'")
		end

		-- make sure the gimmeReset event exists
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE timer = 'gimmeReset'")
		row = cursor:fetch({}, "a")

		if not row then
			conn:execute("INSERT INTO `timedEvents` (`timer`, `delayMinutes`, `nextTime`, `disabled`) VALUES ('gimmeReset', '120', CURRENT_TIMESTAMP, '0'")
		end


		-- look for any events due to be triggered
		cursor,errorString = conn:execute("SELECT * FROM timedEvents WHERE nextTime <= NOW() AND disabled = 0")

		row = cursor:fetch({}, "a")
		while row do
			if row.timer == "announcements" then
				conn:execute("UPDATE timedEvents SET nextTime = NOW() + INTERVAL " .. row.delayMinutes .. " MINUTE WHERE timer = 'announcements'")
				sendNextAnnouncement()
			end

			if row.timer == "gimmeReset" then
				conn:execute("UPDATE timedEvents SET nextTime = NOW() + INTERVAL " .. row.delayMinutes .. " MINUTE WHERE timer = 'gimmeReset'")
				gimmeReset()
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function sendNextAnnouncement()
	local counter, cursor, errorString, rows, row

	if (tonumber(botman.playersOnline) == 0) then -- don't bother if nobody is there to see it
		return
	end

	counter = 1

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM announcements")
		rows = cursor:numrows()
		row = cursor:fetch({}, "a")
		while row do
			if tonumber(server.nextAnnouncement) == counter then
				conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0,0,'" .. escape(row.message) .. "')")
			end

			counter = counter + 1
			row = cursor:fetch(row, "a")
		end
	end

	server.nextAnnouncement = server.nextAnnouncement + 1
	if (server.nextAnnouncement > rows) then server.nextAnnouncement = 1 end
	conn:execute("UPDATE server SET nextAnnouncement = " .. server.nextAnnouncement)
end


function getLastCommandIndex(code)
	local cursor, errorString, row

	cursor,errorString = conn:execute("SELECT MAX(cmdIndex) AS lastIndex FROM botCommands WHERE cmdCode = '" .. escape(code) .. "'")
	row = cursor:fetch({}, "a")

	return tonumber(row.lastIndex) + 1
end


function canSetWaypointHere(steam, x, z)
	local k, v, dist

	-- check for nearby bases that are not friendly
	for k, v in pairs(players) do
		if (v.homeX ~= nil) and k ~= steam then
				if (v.homeX ~= 0 and v.homeZ ~= 0) then
				dist = distancexz(x, z, v.homeX, v.homeZ)

				if (tonumber(dist) < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false, k
					end
				end
			end
		end

		if (v.home2X ~= nil) and k ~= steam then
				if (v.home2X ~= 0 and v.home2Z ~= 0) then
				dist = distancexz(x, z, v.home2X, v.home2Z)

				if (dist < tonumber(v.protectSize) + 10) then
					if not isFriend(k, steam) then
						return false, k
					end
				end
			end
		end
	end

	-- also check locations
	for k, v in pairs(locations) do
		if players[steam].inLocation == v.name then
			if not v.allowWaypoints then
				return false, k
			end
		end
	end

	return true
end


function removeInvalidItems()
	-- remove invalid items from gimmePrizes
	conn:execute("DELETE FROM `gimmePrizes` WHERE name NOT IN (select itemName from spawnableItems)")

	-- update gimmePrizes prize names to match case of itemName in spawnableItems
	conn:execute("UPDATE gimmePrizes INNER JOIN spawnableItems ON spawnableItems.itemName = gimmePrizes.name SET gimmePrizes.name = spawnableItems.itemName")

	-- remove invalid items from the shop
	conn:execute("DELETE FROM `shop` WHERE item NOT IN (select itemName from spawnableItems)")

	-- update shop item names to match case of itemName in spawnableItems
	conn:execute("UPDATE shop INNER JOIN spawnableItems ON spawnableItems.itemName = shop.item SET shop.item = spawnableItems.itemName")

	-- remove invalid items from badItems
	conn:execute("DELETE FROM `badItems` WHERE item NOT IN (select itemName from spawnableItems)")

	-- update badItems item name to match case of itemName in spawnableItems
	conn:execute("UPDATE badItems INNER JOIN spawnableItems ON spawnableItems.itemName = badItems.item SET badItems.item = spawnableItems.itemName")

	-- remove invalid items from restrictedItems
	conn:execute("DELETE FROM `restrictedItems` WHERE item NOT IN (select itemName from spawnableItems)")

	-- update restrictedItems item name to match case of itemName in spawnableItems
	conn:execute("UPDATE restrictedItems INNER JOIN spawnableItems ON spawnableItems.itemName = restrictedItems.item SET restrictedItems.item = spawnableItems.itemName")

	-- refresh the restrictedItems table
	loadRestrictedItems()

	-- refresh the badItems table
	loadBadItems()

	irc_chat(server.ircMain, "Finished validating items.")
end


function collectSpawnableItemsList()
	-- flag items in various tables so we can remove invalid items later
	if botman.dbConnected then
		conn:execute("TRUNCATE TABLE spawnableItems")
		conn:execute("UPDATE badItems SET validated = 1")
		conn:execute("UPDATE gimmePrizes SET validated = 1")
		conn:execute("UPDATE restrictedItems SET validated = 1")
		conn:execute("UPDATE shop SET validated = 1")
	end

	send("li a")
	send("li e")
	send("li i")
	send("li o")
	send("li u")

	send("pm bot_RemoveInvalidItems")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 6
	end
end


function isAdminOnline()
	-- this function helps us choose different actions depending on if an admin is playing or not.
	local k, v

	for k,v in pairs(igplayers) do
		if v.accessLevel < 3 then
			return true
		end
	end

	return false
end


function isDestinationAllowed(steam, x, z)
	local outsideMap, outsideMapDonor, loc

	outsideMap = squareDistance(x, z, server.mapSize)
	outsideMapDonor = squareDistance(x, z, server.mapSize + 5000)
	loc = inLocation(x, z)

	-- prevent player exceeding the map limit unless an admin and ignoreadmins is false
	if outsideMap and not players[steam].donor and (accessLevel(steam) > 3) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	if outsideMapDonor and (accessLevel(steam) > 3 or not botman.ignoreAdmins) then
		if not loc then
			return false
		else
			-- check the locations access level restrictions
			if tonumber(locations[loc].accessLevel) < accessLevel(steam) then
				return false
			end
		end
	end

	return true
end


function searchBlacklist(IP, name)
	local IPInt

	IPInt = IPToInt(IP)
	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. IPInt .. " AND EndIP >= " .. IPInt)
	row = cursor:fetch({}, "a")

	if row then
		if igplayers[name] then
			message("pm " .. steam .. " [" .. server.chatColour .. "]Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP .. "[-]")
		else
			irc_chat(name, "Found in blacklist.  startIP = " .. row.StartIP .. ", endIP = " .. row.EndIP)
		end
	else
		if igplayers[name] then
			message("pm " .. steam .. " [" .. server.chatColour .. "]" .. IP .. " is not in the blacklist.[-]")
		else
			irc_chat(name, IP .. " is not in the blacklist.")
		end
	end
end


function savePlayers()
	local k,v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end
end


function setChatColour(steam, level)
	local access

	if players[steam].prisoner then
		if string.upper(server.chatColourPrisoner) ~= "FFFFFF" then
			send("cpc " .. steam .. " " .. server.chatColourPrisoner .. " 1")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			return -- force prison colour
		end
	end

	access = accessLevel(steam)

	if level ~= nil then
		access = tonumber(level)
	end

	-- change the colour of the player's name
	if players[steam].chatColour ~= "" then
		if string.upper(string.sub(players[steam].chatColour, 1, 6)) ~= "FFFFFF" then
			send("cpc " .. steam .. " " .. stripAllQuotes(players[steam].chatColour) .. " 1")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			return
		end
	end

	if (access > 3 and access < 11) then
		send("cpc " .. steam .. " " .. server.chatColourDonor .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if access == 0 then
		send("cpc " .. steam .. " " .. server.chatColourOwner .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if access == 1 then
		send("cpc " .. steam .. " " .. server.chatColourAdmin .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if access == 2 then
		send("cpc " .. steam .. " " .. server.chatColourMod .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if access == 90 then
		send("cpc " .. steam .. " " .. server.chatColourPlayer .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if access == 99 then
		send("cpc " .. steam .. " " .. server.chatColourNewPlayer .. " 1")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end
end


function isLocationOpen(loc)
	local timeOpen, timeClosed, isOpen, closingSoon, gameHour

	gameHour = tonumber(server.gameHour)
	timeOpen = tonumber(locations[loc].timeOpen)
	timeClosed = tonumber(locations[loc].timeClosed)
	isOpen = true
	closingSoon = false

	-- check the location for opening and closing times
	if tonumber(locations[loc].dayClosed) > 0 then
		if ((server.gameDay + server.hordeNight - locations[loc].dayClosed) % server.hordeNight == 0) then
			return false, false
		end
	end

	if timeOpen == timeClosed then
		isOpen = true
	else
		if timeOpen < timeClosed then
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour < timeOpen then
				isOpen = false
			end
		else
			if gameHour >= timeClosed then
				isOpen = false
			end

			if gameHour >= timeOpen then
				isOpen = true
			end
		 end

		if timeClosed == 0 and gameHour == 23 then
			closingSoon = true
		end

		if timeClosed - gameHour == 1 then
			closingSoon = true
		end
	end

	return isOpen, closingSoon
end


function countGBLBans(steam)
	players[steam].GBLBans = 0

	cursor,errorString = connBots:execute("SELECT COUNT(GBLBan) AS totalBans FROM bans WHERE steam = '" .. steam .. "'")
	row = cursor:fetch({}, "a")
	players[steam].GBLBans = tonumber(row.totalBans)
end


function windowMessage(window, message, override)
	if server.enableWindowMessages or override then
		cecho(window, message)
	end
end


function scanForPossibleHackersNearby(steam, world)
	local k,v,dist,msg

	dist = 0

	for k,v in pairs(igplayers) do
		if (tonumber(players[k].hackerScore) > 20) and players[k].newPlayer then
			if world == nil then
				dist = distancexz(igplayers[steam].xPos, igplayers[steam].zPos, v.xPos, v.zPos)
			end

			if dist < 301 then
				if locations["exile"] then
					players[k].exiled = 1
					players[k].silentBob = true
					players[k].canTeleport = false
					if botman.dbConnected then conn:execute("UPDATE players SET exiled = 1, silentBob = 1, canTeleport = 0 WHERE steam = " .. k) end

					if world ~= nil then
						msg = v.name .. " has been sent to exile, detected with a non-zero hacker score."
					else
						msg = v.name .. " has been sent to exile, detected near " .. players[steam].name .. " with a non-zero hacker score."
					end

					message("say [" .. server.alertColour .. "]" .. msg .. "[-]")
					irc_chat(server.ircAlerts, server.gameDate .. " " .. msg)
				else
					timeoutPlayer(k, "reported by player and found with a non-zero hacker score", false)
				end
			end
		end
	end
end


function registerHelp(tmp)
	if botman.dbConnected then conn:execute("INSERT INTO helpCommands (command, description, notes, keywords, accessLevel, ingameOnly) VALUES ('" .. escape(tmp.command) .. "','" .. escape(tmp.description) .. "','" .. escape(tmp.notes) .. "','" .. escape(tmp.keywords) .. "'," .. tmp.accessLevel .. "," .. tmp.ingameOnly .. ")") end
	if botman.dbConnected then conn:execute("INSERT INTO helpTopicCommands (topicID, commandID) VALUES (" .. topicID .. "," .. commandID .. ")") end
	commandID = commandID + 1
end


function isValidSteamID(steam)
if (debug) then dbug("debug isValidSteamID line " .. debugger.getinfo(1).currentline) end
	-- here we're testing 2 things.  that the id is numeric and that it contains 17 digits
	-- I'm also testing that it begins with 7656.  As far as I know all Steam keys begin with this.

	if string.len(steam) ~= 17 then
		return false
	end

	if string.sub(steam, 1, 4) ~= "7656" then
		return false
	end

	if ToInt(steam) == nil then
		return false
	end

	return true
end


function removeBadPlayerRecords()
	local k,v

	for k,v in pairs(players) do
		if (tonumber(v.id) < 1) then
			igplayers[k] = nil
			players[k] = nil
		end
	end

	if botman.dbConnected then conn:execute("DELETE FROM players WHERE id < 1") end
end


function timeRemaining(finishTime)
	local diff, days, hours, minutes

	diff = os.difftime(finishTime, os.time())
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return days, hours, minutes
end


function alertSpentMoney(steam, amount)
	if server.alertSpending then
		message("pm " .. steam .. " [" .. server.warnColour .. "]You spent " .. amount .. " " .. server.moneyPlural .. "[-]")
	end
end


function fixBot()
	local k, v, fixTables, faultCount

	fixTables = false
	faultCount = 0

	fixMissingStuff()
	fixShop()
	enableTimer("ReloadScripts")
	getServerData(true)

	-- join the irc server
	if botman.customMudlet then
		joinIRCServer()
	end

	botman.fixingBot = false

	-- check in game player's coordinates. If all are 0 0 0, there's a fault.  It could be a missing table change so force the bot to redo them all.
	for k,v in pairs(igplayers) do
		if (math.floor(v.xPos) == 0) and (math.floor(v.yPos) == 0) and (math.floor(v.zPos) == 0) then
			faultCount = faultCount + 1
		end
	end

	if tonumber(faultCount) > 0 then
		if botman.dbConnected then
			conn:execute("TRUNCATE altertables")
			alertAdmins("The bot may become unresponsive for a while, it will do table maintenance in one minute.  When it comes back, the bot will need to be restarted to complete the maintenance.", "alert")
			irc_chat(server.ircMain, "The bot may become unresponsive for a while, it will do table maintenance in one minute.  When it comes back, the bot will need to be restarted to complete the maintenance.")
			tempTimer( 60, [[alterTables()]] )
		end
	end

	--irc_chat(server.ircMain, "Validating shop and gimme prize items.")
	--collectSpawnableItemsList()
end


function addFriend(player, friend, auto)
	if auto == nil then auto = false end

	-- give a player a friend (yay!)
	-- returns true if a friend was added or false if already friends with them

	if (not string.find(friends[player].friends, friend)) then
		if auto then
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 1)") end
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. player .. "," .. friend .. ", 0)") end
		end

		friends[player].friends = friends[player].friends .. "," .. friend
		return true
	else
		return false
	end
end


function getFriends(line)
	local pid, fpid, i, temp, max

	temp = string.split(line, ",")
	pid = string.trim(string.sub(temp[1], 14, 30))
	fpid = string.trim(string.sub(temp[2], 10, 26))

	-- delete auto-added friends from the MySQL table
	if botman.dbConnected then conn:execute("DELETE FROM friends WHERE steam = " .. pid .. " AND autoAdded = 1") end

	-- add friends read from Coppi's lpf command
	-- grab the first one
	if not string.find(friends[pid].friends, fpid) then
		addFriend(pid, fpid, true)
	else
		if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
	end

	-- grab the rest
	max = table.maxn(temp)
	for i=3,max,1 do
		fpid = string.trim(temp[i])
		if not string.find(friends[pid].friends, fpid) then
			addFriend(pid, fpid, true)
		else
			if botman.dbConnected then conn:execute("INSERT INTO friends (steam, friend, autoAdded) VALUES (" .. pid .. "," .. fpid .. ", 1)") end
		end
	end
end


function trimLogs()
	local files, file, temp, k, v
	local yearPart, monthPart, dayPart

	files = {}

	for file in lfs.dir(homedir .. "/log") do
		if lfs.attributes(file,"mode") == nil then
			temp = string.split(file, "#")

			if temp[2] ~= nil then
				files[file] = {}
				files[file].delete = false
				files[file].date = temp[1]
				files[file].dateSplit = string.split(temp[1], "-")
			end
		end
	end

	for k,v in pairs(files) do
		if yearPart == nil then
			if v.dateSplit[1] == os.date('%Y') then
				yearPart = 1
			end

			if v.dateSplit[2] == os.date('%Y') then
				yearPart = 2
			end

			if v.dateSplit[3] == os.date('%Y') then
				yearPart = 3
			end
		end

		if dayPart == nil then
			if tonumber(v.dateSplit[1]) > 12 and yearPart ~= 1 then
				dayPart = 1
			end

			if tonumber(v.dateSplit[2]) > 12 and yearPart ~= 2 then
				dayPart = 2
			end

			if tonumber(v.dateSplit[3]) > 12 and yearPart ~= 3 then
				dayPart = 3
			end
		end

		if yearPart ~= nil and dayPart ~= nil then
			monthPart = 1

			if yearPart == 1 or dayPart == 1 then
				monthPart = 2
			end

			if yearPart == 2 or dayPart == 2 then
				monthPart = 3
			end
		end
	end

	for k,v in pairs(files) do
		fileDate = os.time({year = v.dateSplit[yearPart], month = v.dateSplit[monthPart], day = v.dateSplit[dayPart], hour = 0, min = 0, sec = 0})
		if os.time() - fileDate > 604800 then -- older than 7 days
			os.remove(homedir .. "/log/" .. k)
		end
	end
end

function removeEntities()
	-- remove any entities that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(otherEntities) do
		if v.remove ~= nil then
			otherEntities[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxOtherEntities = maxCount
end


function updateOtherEntities(entityID, entity)
	local k, v, entityLower

	entityLower = string.lower(entity)

	if otherEntities == nil then
		otherEntities = {}
	end

	if otherEntities[entityID] == nil then
		-- new entity so add it to otherEntities
		otherEntities[entityID] = {}
		otherEntities[entityID].entity = entity
		otherEntities[entityID].doNotSpawn = false
		otherEntities[entityID].doNotDespawn = false

		-- don't despawn if it's cute or delicious
		if string.find(entityLower, "pig") or string.find(entityLower, "boar") or string.find(entityLower, "stag") or string.find(entityLower, "chicken") or string.find(entityLower, "rabbit") then
			otherEntities[entityID].doNotDespawn = true
		end
	else
		-- not new entity but entityID for this entity has changed so look for and remove the old entity and add it with the new entityID
		if otherEntities[entityID].entity ~= entity then
			for k,v in pairs(otherEntities) do
				if v.entity == entity then
					otherEntities[k] = nil
				end
			end

			-- now add the entity again with the new entityID
			otherEntities[entityID] = {}
			otherEntities[entityID].entity = entity
			otherEntities[entityID].doNotSpawn = false
			otherEntities[entityID].doNotDespawn = false
			otherEntities[entityID].remove = nil

			-- don't despawn if it's cute or delicious
			if string.find(entityLower, "pig") or string.find(entityLower, "boar") or string.find(entityLower, "stag") or string.find(entityLower, "chicken") or string.find(entityLower, "rabbit") then
				otherEntities[entityID].doNotDespawn = true
			end
		end
	end
end


function removeZombies()
	-- remove any zombies that are flagged for removal after updating the list
	local k, v
	local maxCount = 0

	for k,v in pairs(gimmeZombies) do
		if v.remove then
			gimmeZombies[k] = nil
		else
			maxCount = maxCount + 1
		end
	end

	botman.maxGimmeZombies = maxCount
end


function updateGimmeZombies(entityID, zombie)
	local k, v, zombieLower

	zombieLower = string.lower(zombie)

	if gimmeZombies[entityID] == nil then
		-- new zombie so add it to gimmeZombies
		gimmeZombies[entityID] = {}
		gimmeZombies[entityID].zombie = zombie
		gimmeZombies[entityID].minPlayerLevel = 1
		gimmeZombies[entityID].minArenaLevel = 1
		gimmeZombies[entityID].bossZombie = false
		gimmeZombies[entityID].doNotSpawn = false

		if string.find(zombieLower, "cop") or string.find(zombieLower, "dog") or string.find(zombieLower, "bear") or string.find(zombieLower, "feral") or string.find(zombieLower, "radiated") or string.find(zombieLower, "behemoth") or string.find(zombieLower, "template") then
			gimmeZombies[entityID].doNotSpawn = true
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
		else
			if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
		end

		gimmeZombies[entityID].maxHealth = 0
	else
		-- not new zombie but entityID for this zombie has changed so look for and remove the old zombie and add it with the new entityID
		if gimmeZombies[entityID].zombie ~= zombie then
			for k,v in pairs(gimmeZombies) do
				if v.zombie == zombie then
					gimmeZombies[k] = nil
				end
			end

			-- now add the zombie again with the new entityID
			gimmeZombies[entityID] = {}
			gimmeZombies[entityID].zombie = zombie
			gimmeZombies[entityID].minPlayerLevel = 1
			gimmeZombies[entityID].minArenaLevel = 1
			gimmeZombies[entityID].bossZombie = false
			gimmeZombies[entityID].doNotSpawn = false

			if string.find(zombieLower, "cop") or string.find(zombieLower, "dog") or string.find(zombieLower, "bear") or string.find(zombieLower, "feral") or string.find(zombieLower, "radiated") or string.find(zombieLower, "behemoth") or string.find(zombieLower, "template") then
				gimmeZombies[entityID].doNotSpawn = true
				if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 1 WHERE entityID = " .. entityID) end
			else
				if botman.dbConnected then conn:execute("UPDATE gimmeZombies SET bossZombie = 0, doNotSpawn = 0 WHERE entityID = " .. entityID) end
			end

			gimmeZombies[entityID].maxHealth = 0
			gimmeZombies[entityID].remove = nil
		end
	end
end

function restrictedCommandMessage()
	local r

	chatvars.restrictedCommand = true

	if not igplayers[chatvars.playerid].restrictedCommand then
		igplayers[chatvars.playerid].restrictedCommand = true
		return("This command is restricted")
	else
		r = rand(16)
		if r == 1 then return("It's still restricted") end
		if r == 2 then return("This command is not happening") end
		if r == 3 then return("Which part of NO are you having trouble with?") end
		if r == 4 then return("You again?") end
		if r == 5 then return("We've been over this. N. O.") end
		if r == 6 then return("no No NO!") end
		if r == 7 then return("Have this command, you shall not.") end
		if r == 8 then return("Seriously?") end
		if r == 9 then return("This command is not for you.") end
		if r == 10 then return("Denied!") end
		if r == 11 then return("Give up.  You aren't using this command.") end

		if r == 12 then
			send("give " .. igplayers[chatvars.playerid].id .. " turd 1")

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end

			return("I don't give a shit. That was a lie, but you're still not using this command.")
		end

		if r == 13 then return("Bored now.") end
		if r == 14 then return("[DENIED]  [DENI[DEN[DENIED]ENIED]NIED]  [DENIED]") end
		if r == 15 then return("A bit slow are we? Noooooooooooooooo.") end
		if r == 16 then return("Yyyyyyeeee No.") end
	end
end


function downloadHandler(event, ...)
   if event == "sysDownloadDone" then
      finishDownload(...)
   elseif event == "sysDownloadError" then
	   failDownload(...)
	end
end


function finishDownload(filePath)
	local file, ln, codeVersion, codeBranch

	if isFile(homedir .. "/temp/version.txt") then
		file = io.open(homedir .. "/temp/version.txt", "r")
		codeVersion = file:read "*a"
		codeBranch = file:read "*a"
		file:close()
	end
end


function failDownload(filePath)

end


function isReservedName(player, steam)
	local k, v, pos

	-- strip any trailing (1) or other numbers in brackets
	if string.find(player, "%(%d+%)$") then
		player = string.sub(player, 1, string.find(player, "%(%d+%)$") - 1)
	end

	for k,v in pairs(players) do
		if (v.name == player) and (k ~= steam) then
			if tonumber(v.accessLevel) < 3 then
				return true
			end

			if tonumber(v.accessLevel) ~= tonumber(accessLevel(steam)) and igplayers[k] then
				return true
			end
		end
	end

	return false
end


function inWhitelist(steam)
	local cursor, errorString, row

	-- is the player in the whitelist?
	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM whitelist WHERE steam = " .. steam)
		row = cursor:fetch({}, "a")

		if row then
			return true
		else
			return false
		end
	else
		return false
	end
end


function atHome(steam)
	local dist, size, greet, home, time, r

	greet = false
	home = false

	if players[steam].lastAtHome == nil then
		players[steam].lastAtHome = os.time()
	end

	-- base 1
	if math.abs(players[steam].homeX) > 0 and math.abs(players[steam].homeZ) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].homeX, players[steam].homeZ)
		size = tonumber(players[steam].protectSize)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	-- base 2
	if math.abs(players[steam].home2X) > 0 and math.abs(players[steam].home2Z) > 0 then
		dist = distancexz(math.floor(players[steam].xPos), math.floor(players[steam].zPos), players[steam].home2X, players[steam].home2Z)
		size = tonumber(players[steam].protect2Size)

		if (dist <= size + 30) then
			home = true

			if not players[steam].atHome then
				greet = true
			end
		end
	end

	if greet then
		time = os.time() - players[steam].lastAtHome

		if time > 300 and time <= 900 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Welcome home " .. players[steam].name .. "[-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Back so soon " .. players[steam].name .. "?[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back![-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home sweet home :)[-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again[-]") end
		end

		if time > 900 and time <= 1800 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You're back " .. players[steam].name .. "! Welcome home :)[-]")
		end

		if time > 1800 and time <= 3600 then
			r = rand(5)
			if r == 1 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 2 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home again, home again. Ziggity zig.[-]") end
			if r == 3 then message("pm " .. steam .. " [" .. server.chatColour .. "]Look what the cat dragged in.  Hello " .. players[steam].name .. "[-]") end
			if r == 4 then message("pm " .. steam .. " [" .. server.chatColour .. "]Home at last " .. players[steam].name .. "![-]") end
			if r == 5 then message("pm " .. steam .. " [" .. server.chatColour .. "]You're back! So nice of you to drop by.[-]") end
		end

		if time > 3600 then
			message("pm " .. steam .. " [" .. server.chatColour .. "]So you decided to come home " .. players[steam].name .. "?[-]")
			message("pm " .. steam .. " [" .. server.chatColour .. "]Dinner's on the floor.[-]")
			r = rand(5)
			if r == 1 then
				send("give " .. steam .. " canDogfood 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if r == 2 then
				send("give " .. steam .. " canCatfood 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if r == 3 then
				send("give " .. steam .. " femur 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if r == 4 then
				send("give " .. steam .. " vegetableStew 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end

			if r == 5 then
				send("give " .. steam .. " meatStew 1")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end
			end
		end
	end

	if home then
		players[steam].atHome = true
		players[steam].lastAtHome = os.time()
	else
		players[steam].atHome = false
	end
end


function calcTimestamp(str)
	-- takes input like 1 week, 1 month, 1 year and outputs a timestamp that much in the future
	local number, period

	str = string.lower(str)
	number = math.abs(math.floor(tonumber(string.match(str, "(-?%d+)"))))

	if string.find(str, "minute") then
		period = 60
	end

	if string.find(str, "hour") then
		period = 60 * 60
	end

	if string.find(str, "day") then
		period = 60 * 60 * 24
	end

	if string.find(str, "week") then
		period = 60 * 60 * 24 * 7
	end

	if string.find(str, "month") then
		period = 60 * 60 * 24 * 30
	end

	if string.find(str, "year") then
		period = 60 * 60 * 24 * 365
	end

	if number == nil or period == nil then
		return os.time()
	else
		return os.time() + period * number
	end
end


function countAlphaNumeric(test)
	local count
	-- return the number of alphanumeric characters in test

	local _, count = string.gsub(test, "%w", "")
	return count
end


function pmsg(msg, all)
	local k,v

	-- queue msg for output by a timer
	for k,v in pairs(igplayers) do
		if all ~= nil or players[k].noSpam == false then
			if botman.dbConnected then conn:execute("INSERT INTO messageQueue (sender, recipient, message) VALUES (0," .. k .. ",'" .. escape(msg) .. ")") end
		end
	end
end


function strDateToTimestamp(strdate)
	-- Unix timestamps end in 2038.  To prevent invalid dates, we will force year to 2030 if it is later.
	local sday, smonth, syear, shour, sminute, sseconds = strdate:match("(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")

	-- don't allow dates over 2030.  timestamps stop at 2038
	if tonumber(syear) > 2030 then syear = 2030 end

	return os.time({year = syear, month = smonth, day = sday, hour = shour, min = sminute, sec = sseconds})
end


function getEquipment(equipment, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(equipment, "|")

	max = table.maxn(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")

		if test[2] == item then
			found = true

			if tonumber(test[3]) > tonumber(quality) then
				quality = tonumber(test[3])
			end
		end
	end

	if found then
		return true, quality
	else
		return false, 0
	end
end


function getInventory(inventory, item)
	-- search the most recent inventory recording for an item and if found return how much there is and best quality if applicable
	local tbl, test, i, found, quantity, quality, max

	found = false
	quality = 0
	quantity = 0
	tbl = string.split(inventory, "|")

	max = table.maxn(tbl)
	for i=1, max, 1 do
		test = string.split(tbl[i], ",")
		if test[3] == item then
			found = true
			quantity = quantity + tonumber(test[2])

			if tonumber(test[4]) > tonumber(quality) then
				quality = tonumber(test[4])
			end
		end
	end

	if found then
		return true, quantity, quality
	else
		return false, 0 , 0
	end
end


function inInventory(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC LIMIT 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt .. row.pack .. row.equipment, "|")

		max = table.maxn(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function inBelt(steam, item, quantity, slot)
	-- search the most recent inventory recording for an item in the belt
	local tbl, test, i, max

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .."  ORDER BY inventoryTrackerID DESC LIMIT 0, 1")
		row = cursor:fetch({}, "a")

		tbl = string.split(row.belt, "|")

		max = table.maxn(tbl)
		for i=1, max, 1 do
			test = string.split(tbl[i], ",")
			if slot ~= nil then
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item and tonumber(test[1]) == slot then
					return true
				end
			else
				if tonumber(test[2]) >= tonumber(quantity) and test[3] == item then
					return true
				end
			end
		end
	end

	return false
end


function mapPosition(steam)
	-- express the player's coordinates as a compass bearing
	local ns, ew

	if tonumber(players[steam].xPos) < 0 then
		ew = math.abs(math.floor(players[steam].xPos)).. " W"
	else
		ew = math.floor(players[steam].xPos) .. " E"
	end

	if tonumber(players[steam].zPos) < 0 then
		ns = math.abs(math.floor(players[steam].zPos)) .. " S"
	else
		ns = math.floor(players[steam].zPos) .. " N"
	end

	return ns .. " " .. ew
end


function validPosition(steam, alert)
	-- check that y position is between bedrock and the max build height
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		return true
	else
		if alert ~= nil then
			message("pm " .. steam .. " [" .. server.chatColour .. "]You cannot do that here. If you recently teleported, wait a bit then try again.[-]")
		end

		return false
	end
end


function savePosition(steam, temp)
	-- helper function to save the players position
	if tonumber(players[steam].yPos) > -1 and tonumber(players[steam].yPos) < 256 then
		-- store the player's current x y z
		if temp == nil then
			players[steam].xPosOld = math.floor(players[steam].xPos)
			players[steam].yPosOld = math.ceil(players[steam].yPos)
			players[steam].zPosOld = math.floor(players[steam].zPos)

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld = " .. players[steam].xPosOld .. ", yPosOld = " .. players[steam].yPosOld .. ", zPosOld = " .. players[steam].zPosOld .. " WHERE steam = " .. steam) end
		else
			players[steam].xPosOld2 = math.floor(players[steam].xPos)
			players[steam].yPosOld2 = math.ceil(players[steam].yPos)
			players[steam].zPosOld2 = math.floor(players[steam].zPos)

			if botman.dbConnected then conn:execute("UPDATE players SET xPosOld2 = " .. players[steam].xPosOld2 .. ", yPosOld2 = " .. players[steam].yPosOld2 .. ", zPosOld2 = " .. players[steam].zPosOld2 .. " WHERE steam = " .. steam) end
		end
	end
end


function seen(steam)
	-- when was a player last seen ingame?
	local words, word, diff, ryear, rmonth, rday, rhour, rmin, rsec
	local dateNow, Now, dateSeen, Seen, days, hours, minutes

	if players[steam].seen == "" then
		return "A new player on for the first time now."
	end

	if igplayers[steam] then
		return players[steam].name .. " is on the server now."
	end

	words = {}
	for word in botman.serverTime:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateNow = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Now = os.time(dateNow)

	words = {}
	for word in players[steam].seen:gmatch("%w+") do table.insert(words, word) end

	ryear = words[1]
	rmonth = words[2]
	rday = string.sub(words[3], 1, 2)
	rhour = string.sub(words[3], 4, 5)
	rmin = words[4]
	rsec = words[5]

	dateSeen = {year=ryear, month=rmonth, day=rday, hour=rhour, min=rmin, sec=rsec}
	Seen = os.time(dateSeen)

	diff = os.difftime(Now, Seen)
	days = math.floor(diff / 86400)

	if (days > 0) then
		diff = diff - (days * 86400)
	end

	hours = math.floor(diff / 3600)

	if (hours > 0) then
		diff = diff - (hours * 3600)
	end

	minutes = math.floor(diff / 60)

	return players[steam].name .. " was last seen " .. days .. " days " .. hours .. " hours " .. minutes .." minutes ago"
end


function messageAdmins(message)
	-- helper function to send a message to all staff
	local k,v

	for k, v in pairs(players) do
		if (accessLevel(k) < 3) then
			if igplayers[k] then
				message("pm " .. k .. " [" .. server.chatColour .. "]" .. message .. "[-]")
			else
				if botman.dbConnected then conn:execute("INSERT INTO mail (sender, recipient, message) VALUES (0," .. k .. ", '" .. escape(message) .. "')") end
			end
		end
	end
end


function kick(steam, reason)
	local tmp

	if reason ~= nil then
		stripAngleBrackets(reason)
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))
		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == 0 then steam = tmp end
	end

	if igplayers[steam] then
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','kick','Player " .. steam .. " " .. escape(players[steam].name) .. " kicked for " .. escape(reason) .. "'," .. steam .. ")") end
	end

	send("kick " .. steam .. " " .. " \"" .. reason .. "\"")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	botman.playersOnline = botman.playersOnline - 1
	irc_chat(server.ircMain, "Player " .. players[steam].name .. " kicked. Reason: " .. reason)
end


function banPlayer(steam, duration, reason, issuer, localOnly)
	local id, tmp, admin, belt, pack, equipment, country, isArchived, playerName

	admin = 0
	playerName = "Not Sure" -- placeholder in case we're banning a steam ID that hasn't played here yet.
	isArchived = false

	if not players[steam] then
		id = LookupArchivedPlayer(steam)

		if not (id == 0) then
			playerName = playersArchived[id].name
			isArchived = true
		end
	else
		isArchived = false
		playerName = players[steam].name
	end

	if accessLevel(steam) < 3 then
		irc_chat(server.ircAlerts, "Request to ban admin " .. playerName .. "  [DENIED]")
		message("pm " .. issuer .. " [" .. server.chatColour .. "]Request to ban admin " .. playerName .. "  [DENIED][-]")
		return
	end

	belt = ""
	pack = ""
	equipment = ""
	country = ""

	if reason == nil then
		reason = "banned"
	else
		stripAngleBrackets(reason)
	end

	if issuer then
		admin = issuer
	end

	tmp = steam
	-- if there is no player with steamid steam, try looking it up incase we got their name instead of their steam
	if not players[steam] then
		steam = LookupPlayer(string.trim(steam))

		if steam == 0 then
			steam = LookupArchivedPlayer(string.trim(steam))
		end

		-- restore the original steam value if nothing matched as we may be banning someone who's never played here.
		if steam == 0 then steam = tmp end
	end

	send("ban add " .. steam .. " " .. duration .. " \"" .. reason .. "\"")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	-- grab their belt, pack and equipment
	if players[steam] or playersArchived[steam] then
		if not isArchived then
			country = players[steam].country
		else
			country = playersArchived[steam].country
		end

		if botman.dbConnected then
			cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. steam .." ORDER BY inventoryTrackerid DESC LIMIT 1")
			row = cursor:fetch({}, "a")
			if row then
				belt = row.belt
				pack = row.pack
				equipment = row.equipment
			end

			if not isArchived then
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(playerName) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
			else
				conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(playersArchived[steam].xPos) .. "," .. math.ceil(playersArchived[steam].yPos) .. "," .. math.floor(playersArchived[steam].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. escape(playerName) .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")")
			end
		end

		irc_chat(server.ircMain, "[BANNED] Player " .. steam .. " " .. playerName .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Player " .. steam .. " " .. playerName .. " has been banned for " .. duration .. " " .. reason)
		alertAdmins("Player " .. playerName .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.db2Connected and not localOnly then
			if players[steam] then
				if tonumber(players[steam].pendingBans) > 0 then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "',1,1)")
					irc_chat(server.ircMain, "Player " .. steam .. " " .. players[steam].name .. " has been globally banned.")
					message("say [" .. server.alertColourColour .. "]" .. players[id].name .. " has been globally banned.[-]")
				else
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(players[steam].timeOnServer) + tonumber(players[steam].playtime) .. "," .. players[steam].score .. "," .. players[steam].playerKills .. "," .. players[steam].zombies .. ",'" .. players[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
				end
			end

			if playersArchived[steam] then
				if tonumber(playersArchived[steam].pendingBans) > 0 then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin, GBLBan, GBLBanActive) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(playersArchived[steam].timeOnServer) + tonumber(playersArchived[steam].playtime) .. "," .. playersArchived[steam].score .. "," .. playersArchived[steam].playerKills .. "," .. playersArchived[steam].zombies .. ",'" .. playersArchived[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "',1,1)")
					irc_chat(server.ircMain, "Player " .. steam .. " " .. playerName .. " has been globally banned.")
					message("say [" .. server.alertColourColour .. "]" .. playerName .. " has been globally banned.[-]")
				else
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "'," .. tonumber(playersArchived[steam].timeOnServer) + tonumber(playersArchived[steam].playtime) .. "," .. playersArchived[steam].score .. "," .. playersArchived[steam].playerKills .. "," .. playersArchived[steam].zombies .. ",'" .. playersArchived[steam].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
				end
			end
		end

		send("llp " .. steam)

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end

		-- Look for and also ban ingame players with the same IP
		for k,v in pairs(igplayers) do
			if v.IP == players[steam].IP and k ~= steam and v.IP ~= "" then
				send("ban add " .. k .. " " .. duration .. " \"same IP as banned player\"")

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				if botman.dbConnected then
					cursor,errorString = conn:execute("SELECT * FROM inventoryTracker WHERE steam = " .. k .." ORDER BY inventoryTrackerid DESC LIMIT 1")
					row = cursor:fetch({}, "a")
					if row then
						belt = row.belt
						pack = row.pack
						equipment = row.equipment
					end

					conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[k].xPos) .. "," .. math.ceil(players[k].yPos) .. "," .. math.floor(players[k].zPos) .. ",'" .. botman.serverTime .. "','ban','Player " .. k .. " " .. escape(players[k].name) .. " has has been banned for " .. duration .. " for " .. escape("same IP as banned player") .. "'," .. k .. ")")
				end

				irc_chat(server.ircMain, "[BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Player " .. k .. " " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")
				alertAdmins("Player " .. players[k].name .. " has been banned for " .. duration .. " same IP as banned player")

				-- add to bots db
				if botman.db2Connected then
					connBots:execute("INSERT INTO bans (bannedTo, steam, reason, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. k .. ",'" .. escape("same IP as banned player") .. "'," .. tonumber(players[k].timeOnServer) + tonumber(players[k].playtime) .. "," .. players[k].score .. "," .. players[k].playerKills .. "," .. players[k].zombies .. ",'" .. players[k].country .. "','" .. escape(belt) .. "','" .. escape(pack) .. "','" .. escape(equipment) .. "','" .. server.botID .. "','" .. admin .. "')")
				end
			end
		end
	else
		-- handle unknown steam id
		if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (0,0,0,'" .. botman.serverTime .. "','ban','Player " .. steam .. " " .. steam .. " has has been banned for " .. duration .. " for " .. escape(reason) .. "'," .. steam .. ")") end
		irc_chat(server.ircMain, "[BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)
		irc_chat(server.ircAlerts, server.gameDate .. " [BANNED] Unknown player " .. steam .. " has been banned for " .. duration .. " " .. reason)

		-- add to bots db
		if botman.db2Connected then
			connBots:execute("INSERT INTO bans (bannedTo, steam, reason, permanent, playTime, score, playerKills, zombies, country, belt, pack, equipment, botID, admin) VALUES ('" .. escape("MISSING") .. "'," .. steam .. ",'" .. escape(reason) .. "',1,0,0,0,0,'','','','','" .. server.botID .. "','" .. admin .. "')")
		end
	end
end


function arrest(steam, reason, bail, releaseTime)
	local banTime = 60
	local cmd

	if not locations["prison"] then
		if tonumber(server.maxPrisonTime) > 0 then
			banTime = server.maxPrisonTime
		end

		message("say [" .. server.alertColour .. "]" .. players[steam].name .. " has been banned for " .. banTime .. " minutes for " .. reason .. ".[-]")
		banPlayer(steam, banTime .. " minutes", reason, "")
		return
	end

	players[steam].prisoner = true
	players[steam].prisonReason = reason

	if releaseTime ~= nil then
		players[steam].prisonReleaseTime = os.time() + (releaseTime * 60)
	else
		players[steam].prisonReleaseTime = os.time() + (server.maxPrisonTime * 60)
	end

	if igplayers[steam] then
		players[steam].prisonxPosOld = math.floor(igplayers[steam].xPos)
		players[steam].prisonyPosOld = math.floor(igplayers[steam].yPos)
		players[steam].prisonzPosOld = math.floor(igplayers[steam].zPos)
		igplayers[steam].xPosOld = math.floor(igplayers[steam].xPos)
		igplayers[steam].yPosOld = math.floor(igplayers[steam].yPos)
		igplayers[steam].zPosOld = math.floor(igplayers[steam].zPos)
		irc_chat(server.ircAlerts, server.gameDate .. " " .. players[steam].name .. " has been sent to prison for " .. reason .. " at " .. igplayers[steam].xPosOld .. " " .. igplayers[steam].yPosOld .. " " .. igplayers[steam].zPosOld)
		setChatColour(steam)
	else
		players[steam].prisonxPosOld = math.floor(players[steam].xPos)
		players[steam].prisonyPosOld = math.floor(players[steam].yPos)
		players[steam].prisonzPosOld = math.floor(players[steam].zPos)
		players[steam].xPosOld = math.floor(players[steam].xPos)
		players[steam].yPosOld = math.floor(players[steam].yPos)
		players[steam].zPosOld = math.floor(players[steam].zPos)
		irc_chat(server.ircAlerts, server.gameDate .. " " .. players[steam].name .. " has been sent to prison for " .. reason .. " at " .. players[steam].xPosOld .. " " .. players[steam].yPosOld .. " " .. players[steam].zPosOld)
	end

	players[steam].bail = bail

	if accessLevel(steam) > 2 and (tonumber(bail) == 0) then
		players[steam].silentBob = true
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, silentBob = 1, bail = 0, prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	else
		if botman.dbConnected then conn:execute("UPDATE players SET prisoner = 1, bail = " .. bail .. ", prisonReleaseTime = " .. players[steam].prisonReleaseTime .. ", prisonxPosOld = " .. players[steam].prisonxPosOld .. ", prisonyPosOld = " .. players[steam].prisonyPosOld .. ", prisonzPosOld = " .. players[steam].prisonzPosOld .. " WHERE steam = " .. steam) end
	end

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM locationSpawns WHERE location='prison'")
		rows = cursor:numrows()

		if rows > 0 then
			randomTP(steam, "prison")
		else
			cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
			teleport(cmd, steam)
		end
	else
		cmd = "tele " .. steam .. " " .. locations["prison"].x .. " " .. locations["prison"].y .. " " .. locations["prison"].z
		teleport(cmd, steam)
	end

	message("say [" .. server.warnColour .. "]" .. players[steam].name .. " has been sent to prison.  Reason: " .. reason .. ".[-]")
	message("pm " .. steam .. " [" .. server.chatColour .. "]You are confined to prison until released.[-]")

	if tonumber(bail) > 0 then
		message("pm " .. steam .. " [" .. server.chatColour .. "]You can release yourself for " .. bail .. " " .. server.moneyPlural .. ".[-]")
		message("pm " .. steam .. " [" .. server.chatColour .. "]Type " .. server.commandPrefix .. "bail to release yourself if you have the " .. server.moneyPlural .. ".[-]")
	end

	if tonumber(releaseTime) > 0 then
		days, hours, minutes = timeRemaining(os.time() + (releaseTime * 60))
		message("pm " .. steam .. " [" .. server.chatColour .. "]You will be released in " .. days .. " days " .. hours .. " hours and " .. minutes .. " minutes.[-]")
	end

	if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','prison','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to prison for " .. escape(reason) .. "'," .. steam .. ")") end
end


function timeoutPlayer(steam, reason, bot)
	-- if the player is not already in timeout, send them there.
	if players[steam].timeout == false and players[steam].botTimeout == false then
		players[steam].timeout = true
		if accessLevel(steam) > 2 then players[steam].silentBob = true end
		if bot then players[steam].botTimeout = true end -- the bot initiated this timeout
		-- record their position for return
		players[steam].xPosTimeout = math.floor(players[steam].xPos)
		players[steam].yPosTimeout = math.ceil(players[steam].yPos) + 1
		players[steam].zPosTimeout = math.floor(players[steam].zPos)

		if botman.dbConnected then
			conn:execute("UPDATE players SET timeout = 1, botTimeout = " .. dbBool(bot) .. ", xPosTimeout = " .. players[steam].xPosTimeout .. ", yPosTimeout = " .. players[steam].yPosTimeout .. ", zPosTimeout = " .. players[steam].zPosTimeout .. " WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event, steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','timeout','Player " .. steam .. " " .. escape(players[steam].name) .. " has has been sent to timeout for " .. escape(reason) .. "'," .. steam .. ")")
		end

		-- then teleport the player to timeout
		igplayers[steam].tp = 1
		igplayers[steam].hackerTPScore = 0

		send("tele " .. steam .. " " .. players[steam].xPosTimeout .. " 60000 " .. players[steam].zPosTimeout)

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end

		message("say [" .. server.chatColour .. "]Sending player " .. players[steam].name .. " to timeout for " .. reason .. "[-]")
		irc_chat(server.ircAlerts, server.gameDate .. " [TIMEOUT] Player " .. steam .. " " .. players[steam].name .. " has been sent to timeout for " .. reason)
	end
end


function checkRegionClaims(x, z)
	local cursor, errorString, row

	if botman.dbConnected then
		cursor,errorString = conn:execute("SELECT * FROM keystones WHERE floor(x / 512) =  " .. x .. " AND floor(z / 512) = " .. z)
		row = cursor:fetch({}, "a")
		while row do
			if row.remove == "1" then
				send("rlp " .. row.x .. " " .. row.y .. " " .. row.z)

				if botman.getMetrics then
					metrics.telnetCommands = metrics.telnetCommands + 1
				end

				conn:execute("UPDATE keystones SET remove = 2 WHERE steam = " .. row.steam .. " AND x = " .. row.x .. " AND y = " .. row.y .. " AND z = " .. row.z )
			end

			row = cursor:fetch(row, "a")
		end
	end
end


function dbWho(name, x, y, z, dist, days, hours, height, steamid, ingame)
	local cursor, errorString, row, counter, isStaff

	isStaff = false

	if days == nil then days = 1 end
	if height == nil then height = 5 end

	if not botman.dbConnected then
		return
	end

	if players[steamid] then
		if tonumber(players[steamid].accessLevel) < 3 then
			isStaff = true
		end
	end

	conn:execute("DELETE FROM searchResults WHERE owner = " .. steamid)

	if tonumber(hours) > 0 then
		cursor,errorString = conn:execute("SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(hours) * 3600)) .. "'")
	else
		cursor,errorString = conn:execute("SELECT DISTINCT steam, session FROM tracker WHERE abs(x - " .. x .. ") <= " .. dist .. " AND ABS(z - " .. z .. ") <= " .. dist .. " AND ABS(y - " .. y .. ") <= " .. height .. " AND timestamp >= '" .. os.date("%Y-%m-%d %H:%M:%S", os.time() - (tonumber(days) * 86400)) .. "'")
	end

	row = cursor:fetch({}, "a")
	counter = 1
	rows = cursor:numrows()

	if not ingame then
		if tonumber(rows) > 50 then
			irc_chat(name, "****** Report length " .. rows .. " rows.  Cancel it by typing nuke irc")
		end
	end

	while row do
		-- we will use the searchResults table later.  For now we're not doing anything with it.  It will become a lookup table with record numbers.
		--conn:execute("INSERT INTO searchResults (owner, steam, session, counter) VALUES (" .. ownerid .. "," .. row.steam .. "," .. row.session .. "," .. counter .. ")")
		if ingame then
			if isStaff then
				if players[row.steam] then
					message("pm " .. steamid .. " [" .. server.chatColour .. "] #" .. counter .." " .. row.steam .. " " .. players[row.steam].id .. " " .. players[row.steam].name .. " sess: " .. row.session .. "[-]")
				else
					message("pm " .. steamid .. " [" .. server.chatColour .. "] #" .. counter .." " .. row.steam .. " " .. playersArchived[row.steam].id .. " " .. playersArchived[row.steam].name .. " (archived) sess: " .. row.session .. "[-]")
				end
			else
				if players[row.steam] then
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. players[row.steam].name .. " session: " .. row.session .. "[-]")
				else
					message("pm " .. steamid .. " [" .. server.chatColour .. "]" .. playersArchived[row.steam].name .. " session: " .. row.session .. "[-]")
				end
			end
		else
			if isStaff then
				if players[row.steam] then
					irc_chat(name, "#" .. counter .." " .. row.steam .. " " .. players[row.steam].name .. " sess: " .. row.session)
				else
					irc_chat(name, "#" .. counter .." " .. row.steam .. " " .. playersArchived[row.steam].name .. " (archived) sess: " .. row.session)
				end
			else
				if players[row.steam] then
					irc_chat(name, players[row.steam].name .. " session: " .. row.session)
				else
					irc_chat(name, playersArchived[row.steam].name .. " session: " .. row.session)
				end
			end
		end

		counter = counter + 1
		row = cursor:fetch(row, "a")
	end
end


function dailyMaintenance()
	-- put something here to be run when the server date hits midnight
	updateBot()

	-- purge old tracking data and set a flag so we can tell when the database maintenance is complete.
	if tonumber(server.trackingKeepDays) > 0 then
		conn:execute("UPDATE server SET databaseMaintenanceFinished = 0")
		deleteTrackingData(server.trackingKeepDays)
	end

	-- delete telnet logs older than server.telnetLogKeepDays
	os.execute("find " .. homedir .. "/log* -mtime +" .. server.telnetLogKeepDays .. " -exec rm {} \\;")

	return true
end


function startReboot()
	-- add a random delay to mess with dupers
	local rnd = rand(5)

	send("sa")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	botman.rebootTimerID = tempTimer( 10 + rnd, [[finishReboot()]] )
end


function clearRebootFlags()
	botman.nextRebootTest = os.time() + 60
	botman.scheduledRestart = false
	botman.scheduledRestartTimestamp = os.time()
	botman.scheduledRestartPaused = false
	botman.scheduledRestartForced = false
end


function finishReboot()
	local k, v

	tempTimer( 30, [[clearRebootFlags()]] )

	if (botman.rebootTimerID ~= nil) then
		killTimer(botman.rebootTimerID)
		botman.rebootTimerID = nil
	end

	if (rebootTimerDelayID ~= nil) then
		killTimer(rebootTimerDelayID)
		rebootTimerDelayID = nil
	end

	for k, v in pairs(igplayers) do
		kick(k, "Server restarting.")
	end

	botman.ignoreAdmins = true
	send("shutdown")

	if botman.getMetrics then
		metrics.telnetCommands = metrics.telnetCommands + 1
	end

	-- flag all players as offline
	connBots:execute("UPDATE players SET online = 0 WHERE botID = " .. server.botID)

	-- do some housekeeping
	for k, v in pairs(players) do
		v.botQuestion = ""
	end

	conn:execute("TRUNCATE TABLE memTracker")
	conn:execute("TRUNCATE TABLE commandQueue")
	conn:execute("TRUNCATE TABLE gimmeQueue")
end


function newDay()
	local diff, days, restarting, status

	restarting = false

	if server.dateTest == nil then
		server.dateTest = string.sub(botman.serverTime, 1, 10)
	end

	if (string.sub(botman.serverTime, 1, 10) ~= server.dateTest) then
		server.dateTest = string.sub(botman.serverTime, 1, 10)

		-- force logging to start a new file
		startLogging(false)
		startLogging(true)

		dailyMaintenance()
		resetShop()

		if tonumber(botman.playersOnline) < 16 then
			saveLuaTables()
		end

		-- if bot can restart itself and botRestartDay isn't zero, check how many days the bot has been running.
		-- if bot uptime is greater than botRestartDay, restart the bot.
		if server.allowBotRestarts and server.botRestartDay > 0 then
			diff = os.difftime(os.time(), botman.botStarted)
			days = math.floor(diff / 86400)

			if days >= server.botRestartDay then
				restarting = true
				tempTimer( 30, [[restartBot()]] )
			end
		end

		if not restarting then
			-- reload the bot's code.  This may help fix a few issues with slow performance but its more likely due to other stuff the reload does.
			dofile(homedir .. "/scripts/reload_bot_scripts.lua")
			reloadBotScripts(true)
		end

		status = "Server is UP"

		if botman.botOffline then
			status "Server is OFFLINE"
		end

		if relogCount > 6 then
			status "Telnet has crashed."
		end

		if botman.botOffline == false then
			irc_chat("#status", "Bot " .. server.botName .. " on server " .. server.serverName .. " " .. server.IP .. ":" .. server.ServerPort .. " Game version: " .. server.gameVersion)
			irc_chat("#status", "Status: " .. status .. ", bot version: " .. server.botVersion .. " on branch " .. server.updateBranch)
		end
	end
end


function newBotDay()
	-- do stuff when the date changes where the bot is running (usually different to the 7 Days server's date)

end


function IPToInt(ip)
	local o1,o2,o3,o4

	o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	return 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
end


function readIPBlacklist()
	-- very slow.  don't run with a full server
	local ln
	local iprange

	local o1,o2,o3,o4
	local num1,num2

	for ln in io.lines(homedir .. "/cn.csv") do
		iprange = string.split(ln, ",")

		o1,o2,o3,o4 = iprange[1]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num1 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		o1,o2,o3,o4 = iprange[2]:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
		num2 = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4

		connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP) VALUES (" .. num1 .. "," .. num2 .. ")")
	end
end


function Translate(playerid, command, lang, override)
	local words, word, oldCount, matches

	os.remove(botman.userHome .. "/" .. server.botID .. "trans.txt")
	os.execute(botman.userHome .. "/" .. server.botID .. "trans.txt")

	words = {}
	for word in command:gmatch("%S+") do table.insert(words, word) end
	oldCount = table.maxn(words)

	if lang == "" then
		os.execute("trans -b -no-ansi \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	else
		os.execute("trans -b -no-ansi {en=" .. lang .."}  \"" .. command .. "\" > " .. botman.userHome .. "/" .. server.botID .. "trans.txt")
	end

	for ln in io.lines(botman.userHome .. "/" .. server.botID .. "trans.txt") do
		matches = 0
		for word in ln:gmatch("%S+") do
			if string.find(command, word, nil, true) then
				matches = matches + 1
			end
		end

		if matches < 2 then
			if ln ~= command and string.trim(ln) ~= "" then
				if players[playerid].translate == true or override ~= nil then
					message("say [BDFFFF]" .. players[playerid].name .. " [-]" .. ln)
				end

				if players[playerid].translate == false then
					irc_chat(server.ircMain, players[playerid].name .. " " .. ln)
				end
			end
		end
	end

	io.close()
end


function CheckClaimsRemoved()
	local k,v

	for k,v in pairs(igplayers) do
		if players[k].alertRemovedClaims == true then
			message("pm " .. k .. " [" .. server.chatColour .. "]You had expired claims or you placed claims in a restricted area and they have been automatically removed.  You can get them back by typing " .. server.commandPrefix .. "give claims.[-]")
			players[k].alertRemovedClaims = false
		end
	end
end


function CheckBlacklist(steam, ip)
	-- if blacklist action is not exile or ban, nothing happens to the player.
	ip = ip:gsub("::ffff:", "")

	local o1,o2,o3,o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)" )
	local ipint = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	local k, v, cursor, errorString

	if not botman.db2Connected then
		return
	end

	-- test for China IP
	ipint = tonumber(ipint)

	cursor,errorString = connBots:execute("SELECT * FROM IPBlacklist WHERE StartIP <=  " .. ipint .. " AND EndIP >= " .. ipint)
	if cursor:numrows() > 0 then

		if (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			irc_chat(server.ircMain, "Blacklisted IP detected. " .. players[steam].name)
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted IP detected. " .. players[steam].name)
		end

		players[steam].china = true
		players[steam].country = "CN"
		players[steam].ircTranslate = true

		if server.blacklistResponse ~= "ban" and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			-- alert players
			for k, v in pairs(igplayers) do
				if players[k].exiled~=1 and not players[k].prisoner then
					message("pm " .. k .. " Player " .. players[steam].name .. " from a blacklisted country has joined.[-]")
				end
			end
		end

		if server.blacklistResponse == 'exile' and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			if tonumber(players[steam].exiled) == 0 then
				players[steam].exiled = 1
				if botman.dbConnected then conn:execute("UPDATE players SET country = 'CN', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam) end
			end
		end

		if server.blacklistResponse == 'ban' and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			irc_chat(server.ircMain, "Blacklisted player " .. players[steam].name .. " banned.")
			irc_chat(server.ircAlerts, server.gameDate .. " blacklisted player " .. players[steam].name .. " banned.")
			banPlayer(steam, "10 years", "blacklisted", "")
			connBots:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined and banned. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. ip  .. "'," .. steam .. ")")
		end
	else
		reverseDNS(steam, ip)
	end
end


function reverseDNS(steam, ip)
	os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	os.execute("whois " .. ip:gsub("::ffff:", "") .. " > \"" .. homedir .. "/dns/" .. steam .. ".txt\"")
	tempTimer( 60, [[readDNS("]] .. steam .. [[")]] )
end


function readDNS(steam)
	-- if blacklist action is not exile or ban, nothing happens to the player.
	-- NOTE: If blacklist action is nothing, proxies won't trigger a ban or exile response either.

	local file, ln, split, ip1, ip2, exiled, banned, country, proxy, ISP, iprange, IP

	file = io.open(homedir .. "/dns/" .. steam .. ".txt", "r")
	exiled = false
	banned = false
	proxy = false
	country = ""

	for ln in file:lines() do
		ln = string.upper(ln)

		if string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s") then
			a,b = string.find(ln, "%s(%d+)%.(%d+)%.(%d+)%.(%d+)%s")
			iprange = string.sub(ln, a, a+b)
		end

		if (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			for k,v in pairs(proxies) do
				if string.find(ln, string.upper(v.scanString), nil, true) then
					v.hits = tonumber(v.hits) + 1
					proxy = true

					if botman.db2Connected then
						connBots:execute("UPDATE proxies SET hits = hits + 1 WHERE scanString = '" .. escape(k) .. "'")
					end

					if server.blacklistResponse ~= 'nothing' and accessLevel(steam) > 2 then
						if v.action == "ban" or v.action == "" then
							irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Detected proxy " .. v.scanString)
							banPlayer(steam, "10 years", "Banned proxy. Contact us to get unbanned and whitelisted.", "")
							banned = true
						else
							if players[steam].exiled == 0 then
								players[steam].exiled = 1
								irc_chat(server.ircMain, "Player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
								irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " exiled. Detected proxy " .. v.scanString)
								exiled = true
							end
						end
					end
				end
			end
		end

		--if proxy then break end

		if string.find(ln, "ABUSE@") then
			-- record the domain after the @ and store as the player's ISP
			ISP = string.sub(ln, string.find(ln, "ABUSE@") + 6)
			players[steam].ISP = ISP
		end

		if string.find(ln, "CHINA") then
			country = "CN"
			players[steam].country = "CN"
		end

		if string.find(ln, "OUNTRY:") or (ln == "ADDRESS:        CN") or (ln == "ADDRESS:        HK") then
			-- only report country change if CN or HK are involved. For once, don't blame Canada.
			a,b = string.find(ln, "%s(%w+)")
			country = string.sub(ln, a + 1)
			if players[steam].country ~= "" and players[steam].country ~= country and (players[steam].country == "CN" or players[steam].country == "HK" or country == "CN" or country == "HK") and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
				irc_chat(server.ircAlerts, server.gameDate .. " possible proxy detected! Country changed! " .. steam .. " " .. players[steam].name .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country)
				if botman.dbConnected then conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (0,0,0'" .. botman.serverTime .. "','proxy','Suspected proxy used by " .. escape(players[steam].name) .. " " .. players[steam].IP .. " old country " .. players[steam].country .. " new " .. country .. "," .. steam .. ")") end
				proxy = true
			else
				 players[steam].country = country
			end
		end

		-- We consider HongKong to be China since Chinese players connect from there too.
		if (country == "CN" or country == "HK") and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			-- China detected. Add ip range to IPBlacklist table
			irc_chat(server.ircMain, "Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			irc_chat(server.ircAlerts, server.gameDate .. " Chinese IP detected. " .. players[steam].name .. " " .. players[steam].IP)
			players[steam].china = true
			players[steam].ircTranslate = true

			if server.blacklistResponse == 'exile' and not exiled and accessLevel(steam) > 2 then
				if players[steam].exiled == 0 then
					players[steam].exiled = 1
					irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " exiled.")
					irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " exiled.")
					exiled = true
				end
			end

			if server.blacklistResponse == 'ban' and not banned and accessLevel(steam) > 2 then
				irc_chat(server.ircMain, "Chinese player " .. players[steam].name .. " banned.")
				irc_chat(server.ircAlerts, server.gameDate .. " Chinese player " .. players[steam].name .. " banned.")
				banPlayer(steam, "10 years", "blacklisted", "")
				banned = true
			end

			if botman.db2Connected then
				if iprange ~= nil then
					split = string.split(iprange, "-")
					ip1 = IPToInt(string.trim(split[1]))
					ip2 = IPToInt(string.trim(split[2]))

					-- check that player's IP is actually within the discovered IP range
					IP = IPToInt(players[steam].IP)

					if IP >= ip1 and IP <= ip2 then
						irc_chat(server.ircMain, "Added new Chinese IP range " .. iprange .. " to blacklist")
						connBots:execute("INSERT INTO IPBlacklist (StartIP, EndIP, Country, botID, steam, playerName, IP) VALUES (" .. ip1 .. "," .. ip2 .. "'" .. country .. "'," .. server.botID .. "," .. steam .. ",'" .. escape(players[steam].name) .. "','" .. escape(players[steam].IP) .. "')")
					end
				end
			end

			file:close()

			-- got country so stop processing the dns record
			break
		end
	end

	-- alert players
	if blacklistedCountries[country] and server.blacklistResponse ~= 'ban' and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
		for k, v in pairs(igplayers) do
			if players[k].exiled~=1 and not players[k].prisoner then
				message("pm " .. k .. " Player " .. players[steam].name .. " from blacklisted country " .. country .. " has joined.[-]")
			end
		end
	end

	if blacklistedCountries[country] and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
		if server.blacklistResponse == 'ban' and not banned then
			irc_chat(server.ircMain, "Player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " banned. Blacklisted country " .. country)
			banPlayer(steam, "10 years", "Sorry, your country has been blacklisted :(", "")
			banned = true
		end

		if server.blacklistResponse == 'exile' and not exiled then
			if players[steam].exiled == 0 then
				players[steam].exiled = 1
				irc_chat(server.ircMain, "Player " .. players[steam].name .. " exiled. Blacklisted country " .. country)
				irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " exiled. Blacklisted country " .. country)
				exiled = true
			end
		end
	end

	if server.whitelistCountries ~= '' and not whitelistedCountries[country] and (not (whitelist[steam] or players[steam].donor)) and not banned and accessLevel(steam) > 2 then
		irc_chat(server.ircMain, "Player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		irc_chat(server.ircAlerts, server.gameDate .. " player " .. players[steam].name .. " temp banned 1 month. Country not on whitelist " .. country)
		banPlayer(steam, "1 month", "Sorry, this server uses a whitelist.", "")
		banned = true
	end

	if botman.dbConnected then
		if server.blacklistResponse ~= 'nothing' and exiled and (not (whitelist[steam] or players[steam].donor)) and accessLevel(steam) > 2 then
			conn:execute("UPDATE players SET country = '" .. escape(country) .. "', exiled = 1, ircTranslate = 1 WHERE steam = " .. steam)
			conn:execute("INSERT INTO events (x, y, z, serverTime, type, event,steam) VALUES (" .. math.floor(players[steam].xPos) .. "," .. math.ceil(players[steam].yPos) .. "," .. math.floor(players[steam].zPos) .. ",'" .. botman.serverTime .. "','info','Blacklisted player joined. Name: " .. escape(player) .. " SteamID: " .. steam .. " IP: " .. players[steam].IP  .. "'," .. steam .. ")")
		end
	end

	if proxy then
		os.rename(homedir .. "/dns/" .. steam .. "_old.txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/proxies/" .. steam .. "_" .. country .. ".txt")
	else
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end

	if botman.dbConnected then conn:execute("UPDATE players SET country = '" .. country .. "' WHERE steam = " .. steam) end

	file:close()

	if not proxy then
		os.rename(homedir .. "/dns/" .. steam .. ".txt", homedir .. "/dns/" .. steam .. "_old.txt")
	end
end


function initNewPlayer(steam, player, entityid, steamOwner)
	if botman.dbConnected then conn:execute("INSERT INTO players (steam, id, name, steamOwner) VALUES (" .. steam .. "," .. entityid .. ",'" .. escape(player) .. "'," .. steamOwner .. ")") end

	players[steam] = {}
	players[steam].alertMapLimit = false
	players[steam].alertPrison = true
	players[steam].alertPVP = true
	players[steam].alertReset = true
	players[steam].aliases = player .. ","
	players[steam].atHome = false
	players[steam].autoFriend = ""
	players[steam].baseCooldown = 0
	players[steam].bedX = 0
	players[steam].bedY = 0
	players[steam].bedZ = 0
	players[steam].block = false
	players[steam].botTimeout = false
	players[steam].botQuestion = "" -- used for storing the last question the bot asked the player.
	players[steam].bountyReason = ""
	players[steam].cash = 0
	players[steam].chatColour = "FFFFFF"
	players[steam].commandCooldown = 0
	players[steam].country = ""
	players[steam].denyRights = false
	players[steam].donor = false
	players[steam].donorExpiry = os.time()
	players[steam].donorLevel = 0
	players[steam].exiled = 0
	players[steam].firstSeen = os.time()
	players[steam].GBLCount = 0
	players[steam].gimmeCooldown = 0
	players[steam].gimmeCount = 0
	players[steam].hackerScore = 0
	players[steam].home2X = 0
	players[steam].home2Y = 0
	players[steam].home2Z = 0
	players[steam].homeX = 0
	players[steam].homeY = 0
	players[steam].homeZ = 0
	players[steam].id = entityid
	players[steam].ignorePlayer = false -- exclude player from checks like inventory, flying, teleporting etc.
	players[steam].IP = ""
	players[steam].ircPass = ""
	players[steam].ISP = ""
	players[steam].lastBaseRaid = 0
	players[steam].lastChatLine = ""
	players[steam].lastCommand = ""
	players[steam].lastCommandTimestamp = os.time()
	players[steam].lastLogout = os.time()
	players[steam].location = ""
	players[steam].maxWaypoints = server.maxWaypoints
	players[steam].mute = false
	players[steam].name = player
	players[steam].newPlayer = true
	players[steam].overstack = false
	players[steam].overstackItems = ""
	players[steam].overstackScore = 0
	players[steam].overstackTimeout = false
	players[steam].packCooldown = 0
	players[steam].pendingBans = 0
	players[steam].permanentBan = false
	players[steam].ping = 0
	players[steam].playtime = 0
	players[steam].prisoner = false
	players[steam].prisonReason = ""
	players[steam].prisonReleaseTime = 0
	players[steam].prisonxPosOld = 0
	players[steam].prisonyPosOld = 0
	players[steam].prisonzPosOld = 0
	players[steam].protect = false
	players[steam].protect2 = false
	players[steam].protect2Size = server.baseSize
	players[steam].protectSize = server.baseSize
	players[steam].pvpTeleportCooldown = 0
	players[steam].pvpVictim = 0
	players[steam].raiding = false
	players[steam].relogCount = 0
	players[steam].removeClaims = false
	players[steam].reserveSlot = false
	players[steam].sessionCount = 1
	players[steam].returnCooldown = 0
	players[steam].silentBob = false
	players[steam].steam = steam
	players[steam].steamOwner = steamOwner
	players[steam].teleCooldown = 0
	players[steam].timeOnServer = 0
	players[steam].timeout = false
	players[steam].tokens = 0
	players[steam].VACBanned = false
	players[steam].walkies = false
	players[steam].watchPlayer = true
	players[steam].watchPlayerTimer = os.time() + 2419200 -- stop watching in one month.  it will stop earlier once they are upgraded from new player status
	players[steam].waypoint2X = 0
	players[steam].waypoint2Y = 0
	players[steam].waypoint2Z = 0
	players[steam].waypointsLinked = false
	players[steam].waypointX = 0
	players[steam].waypointY = 0
	players[steam].waypointZ = 0
	players[steam].waypointCooldown = server.waypointCooldown
	players[steam].whitelisted = false
	players[steam].xPos = 0
	players[steam].xPosOld = 0
	players[steam].xPosOld2 = 0
	players[steam].yPos = 0
	players[steam].yPosOld = 0
	players[steam].yPosOld2 = 0
	players[steam].zPos = 0
	players[steam].zPosOld = 0
	players[steam].zPosOld2 = 0

	if locations["spawn"] then
		players[steam].location = "spawn"
	end

	if locations["lobby"] then
		players[steam].location = "lobby"
	end

	return true
end


function initNewIGPlayer(steam, player, entityid, steamOwner)
	igplayers[steam] = {}
	igplayers[steam].afk = os.time() + 900
	igplayers[steam].alertLocation = ""
	igplayers[steam].alertRemovedClaims = false
	igplayers[steam].belt = ""
	igplayers[steam].checkNewPlayer = true
	igplayers[steam].connected = true
	igplayers[steam].equipment = ""
	igplayers[steam].fetch = false
	igplayers[steam].firstSeen = os.time()
	igplayers[steam].flyCount = 0
	igplayers[steam].flying = false
	igplayers[steam].flyingHeight = 0
	igplayers[steam].flyingX = 0
	igplayers[steam].flyingY = 0
	igplayers[steam].flyingZ = 0
	igplayers[steam].greet = true
	igplayers[steam].greetdelay = 1000
	igplayers[steam].hackerTPScore = 0
	igplayers[steam].highPingCount = 0
	igplayers[steam].id = entityid
	igplayers[steam].illegalInventory = false
	igplayers[steam].inLocation = ""
	igplayers[steam].inventory = ""
	igplayers[steam].inventoryLast = ""
	igplayers[steam].killTimer = 0
	igplayers[steam].lastHotspot = 0
	igplayers[steam].lastLogin = ""
	igplayers[steam].lastLP = os.time()
	igplayers[steam].lastTPTimestamp = os.time()
	igplayers[steam].name = player
	igplayers[steam].noclipCount = 0
	igplayers[steam].noclipX = 0
	igplayers[steam].noclipY = 0
	igplayers[steam].noclipZ = 0
	igplayers[steam].pack = ""
	igplayers[steam].ping = 0
	igplayers[steam].playGimme = false
	igplayers[steam].readCounter = 0
	igplayers[steam].region = ""
	igplayers[steam].sessionPlaytime = 0
	igplayers[steam].sessionStart = os.time()
	igplayers[steam].spawnedInWorld = false
	igplayers[steam].spawnedReason = "fake reason"
	igplayers[steam].spawnChecked = true
	igplayers[steam].spawnedCoordsOld = "0 0 0"
	igplayers[steam].spawnedCoords = "0 0 0"
	igplayers[steam].spawnPending = false
	igplayers[steam].steam = steam
	igplayers[steam].steamOwner = steamOwner
	igplayers[steam].teleCooldown = 200
	igplayers[steam].timeOnServer = 0
	igplayers[steam].tp = 1
	igplayers[steam].xPos = 0
	igplayers[steam].xPosLast = 0
	igplayers[steam].xPosLastAlert = 0
	igplayers[steam].xPosLastOK = 0
	igplayers[steam].yPos = 0
	igplayers[steam].yPosLast = 0
	igplayers[steam].yPosLastAlert = 0
	igplayers[steam].yPosLastOK = 0
	igplayers[steam].zPos = 0
	igplayers[steam].zPosLast = 0
	igplayers[steam].zPosLastAlert = 0
	igplayers[steam].zPosLastOK = 0

	return true
end


function fixMissingStuff()
	lfs.mkdir(homedir .. "/custom")
	lfs.mkdir(homedir .. "/daily")
	lfs.mkdir(homedir .. "/dns")
	lfs.mkdir(homedir .. "/proxies")
	lfs.mkdir(homedir .. "/temp")
	lfs.mkdir(homedir .. "/scripts")
	lfs.mkdir(homedir .. "/data_backup")
	lfs.mkdir(homedir .. "/chatlogs")

	if not isFile(homedir .. "/custom/gmsg_custom.lua") then
		file = io.open(homedir .. "/custom/gmsg_custom.lua", "a")
		file:write("function gmsg_custom()\n")
		file:write("	calledFunction = \"gmsg_custom\"\n")
		file:write("	\-\- ###################  do not allow remote commands beyond this point ################\n")
		file:write("	if (chatvars.playerid == nil) then\n")
		file:write("		botman.faultyChat = false\n")
		file:write("		return false\n")
		file:write("	end\n")
		file:write("	\-\- ####################################################################################\n")
		file:write("	if (chatvars.words[1] == \"test\" and chatvars.words[2] == \"command\") then\n")
		file:write("		message(\"pm \" .. chatvars.playerid .. \" [\" .. server.chatColour .. \"]This is a sample command in gmsg_custom.lua in the scripts folder.[-]\")\n")
		file:write("		botman.faultyChat = false\n")
		file:write("		return true\n")
		file:write("	end\n")
		file:write("end\n")
		file:close()
	end

	if not isFile(homedir .. "/custom/customIRC.lua") then
		file = io.open(homedir .. "/custom/customIRC.lua", "a")
		file:write("\-\- Any code you put in here is accessed via bot commands on IRC not ingame.\n")
		file:write("\-\- This code is not replaced by bot updates.\n")
		file:write("function customIRC(name, words, wordsOld, msgLower)\n")
		file:write("local ircid\n")
		file:write("ircid = LookupOfflinePlayer(name, \"all\")\n")
		file:write("if (words[1] == \"debug\" and words[2] == \"on\") then\n")
		file:write("server.enableWindowMessages = true\n")
		file:write("irc_chat(name, \"Debugging ON\")\n")
		file:write("return true\n")
		file:write("end\n")
		file:write("if (words[1] == \"debug\" and words[2] == \"off\") then\n")
		file:write("server.enableWindowMessages = false\n")
		file:write("irc_chat(name, \"Debugging OFF\")\n")
		file:write("return true\n")
		file:write("end\n")
		file:write("return false\n")
		file:write("end\n")
		file:close()
	end


	if type(gimmeZombies) ~= "table" then
		gimmeZombies = {}
		send("se")

		if botman.getMetrics then
			metrics.telnetCommands = metrics.telnetCommands + 1
		end
	end

	if benchmarkBot == nil then
		benchmarkBot = false
	end
end


function saveDisconnectedPlayer(steam)
	-- this function has been moved from the player disconnected trigger so we can call it in other places if necessary to ensure all online player data is saved to the database.
	fixMissingPlayer(steam)

	-- update players table with x y z
	players[steam].lastAtHome = nil
	players[steam].protectPaused = nil
	players[steam].protect2Paused = nil

	if igplayers[steam] then
		-- only process the igplayer record if the player is actually online otherwise assume these are already done
		players[steam].xPos = igplayers[steam].xPos
		players[steam].yPos = igplayers[steam].yPos
		players[steam].zPos = igplayers[steam].zPos
		players[steam].playerKills = igplayers[steam].playerKills
		players[steam].deaths = igplayers[steam].deaths
		players[steam].zombies = igplayers[steam].zombies
		players[steam].score = igplayers[steam].score
		players[steam].ping = igplayers[steam].ping
		players[steam].timeOnServer = players[steam].timeOnServer + igplayers[steam].sessionPlaytime

		if (igplayers[steam].sessionPlaytime) > 300 then
			players[steam].relogCount = 0
		end

		if (igplayers[steam].sessionPlaytime) < 60 then
			if not players[steam].timeout and not players[steam].botTimeout and not players[steam].prisoner then
				players[steam].relogCount = tonumber(players[steam].relogCount) + 1
			end
		else
			players[steam].relogCount = tonumber(players[steam].relogCount) - 1
			if tonumber(players[steam].relogCount) < 0 then players[steam].relogCount = 0 end
		end

		players[steam].lastLogout = os.time()
		players[steam].seen = botman.serverTime
	end

	if accessLevel(steam) < 3 then
		if botman.dbConnected then conn:execute("DELETE FROM memTracker WHERE admin = " .. steam) end
	end

	if botman.dbConnected then
		conn:execute("DELETE FROM messageQueue WHERE recipient = " .. steam)
		conn:execute("DELETE FROM gimmeQueue WHERE steam = " .. steam)
		conn:execute("DELETE FROM commandQueue WHERE steam = " .. steam)
		conn:execute("DELETE FROM playerQueue WHERE steam = " .. steam)
	end

	-- delete player from igplayers table
	igplayers[steam] = nil
	lastHotspots[steam] = nil
	invTemp[steam] = nil

	-- update the player record in the database
	updatePlayer(steam)

	if	botman.db2Connected then
		-- insert or update player in bots db
		connBots:execute("INSERT INTO players (server, steam, ip, name, online, botid) VALUES ('" .. escape(server.serverName) .. "'," .. steam .. ",'" .. players[steam].IP .. "','" .. escape(players[steam].name) .. "',0," .. server.botID .. ") ON DUPLICATE KEY UPDATE ip = '" .. players[steam].IP .. "', name = '" .. escape(players[steam].name) .. "', online = 0")
	end

	initReservedSlots()
end


function shutdownBot(steam)
	local k, v

	for k,v in pairs(igplayers) do
		savePlayerData(k)
	end

	saveLuaTables(os.date("%Y%m%d_%H%M%S"))

	if igplayers[steam] then
		message("pm " .. steam .. " [" .. server.chatColour .. "]" .. server.botName .. " is ready to shutdown.  Player data is saved.[-]")
	end

	sendIrc(server.ircMain, server.botName .. " is ready to shutdown.  Player data is saved.")
end
