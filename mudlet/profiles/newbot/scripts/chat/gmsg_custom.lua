function gmsg_custom()
	calledFunction = "gmsg_custom"
	-- ###################  do not allow remote commands beyond this point ################
	if (chatvars.playerid == 0) then
		faultyChat = false
		return false
	end
	-- ####################################################################################
	if (chatvars.words[1] == "test" and chatvars.words[2] == "command") then
		message("pm " .. chatvars.playerid .. " [" .. server.chatColour .. "]This is a sample command in gmsg_custom.lua in the scripts folder.[-]")
		faultyChat = false
		return true
	end
end
