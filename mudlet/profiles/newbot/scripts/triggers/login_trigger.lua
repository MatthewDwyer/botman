function loginTrigger(line)
	lastAction = "Login"
	botman.botOfflineCount = 2

	-- EDIT ME!
	send(telnetPassword)

	botman.botDisabled = false
end
