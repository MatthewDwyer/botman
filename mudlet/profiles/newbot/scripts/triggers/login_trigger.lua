function loginTrigger(line)
	lastAction = "Login"
	botman.botOfflineCount = 2

	send(telnetPassword)

	botman.botDisabled = false
end
