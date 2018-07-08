function loginTrigger()
	lastAction = "Login"
	botman.botOfflineCount = 2
	botman.botConnectedTimestamp = os.time()
	send(telnetPassword)
end
