--[[
	Put code that you are testing in here so you don't need to touch the bot's profile XML file.
	You can output to the bot's lists window with dbug("display some value " .. someValue)
	Or you can out to IRC in the watch channel with dbugi("display some value " .. someValue)

	When you have finished your edits and uploaded trialCode.lua again type /reload code or just say reload code, then you can press the Trial Code button on the right side of Mudlet's screen.
--]]

--[[
Bot ideas!
- Have bot's 'fone home' by simply visiting a url on botman.nz that doesn't exist and I can check the website visits to get an idea of how many bots are out there and which ones are active.
Each bot would visit a fake url including the server name, public port (no pass though), bot name, pve/pvp, number of unique player visits in the last 24 hours

- Use wget to download a file named with the current bot version eg. version_20160818.1  Each release has the date and a point release if I do more than one in a day.  The bots store this
in their server table and if the number is greater than their version, wget a scripts folder off the website, possibly directly into the bot's scripts folder followed by reload code. The file should
also list the names and version numbers of required mods so bots with old or missing mods don't break
--]]

function trialCode()
	local tmp = {}

	dbug("running trialCode()")
	dbugi("running trialCode()")



	dbugi("trialCode() finished")
	dbug("trialCode() finished")
end