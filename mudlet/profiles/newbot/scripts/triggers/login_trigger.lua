function loginTrigger()
	if type(botman) ~= "table" then
		botman = {}
	end

	lastAction = "Login"
	botman.botOfflineCount = 0
	botman.botConnectedTimestamp = os.time()
	botman.lastServerResponseTimestamp = os.time()
	send(telnetPassword)
end
