function fixTeleportsBug()
	irc_chat(server.ircMain, "Fixing teleports")

	-- there was a typo in gmsg_teleports.lua where there are 4 near identical commmands,
	-- /opentp, /closetp, and /tele <name> open and /tele <name> closetp
	-- the typo was in the tele versions where instead of storing XYZ to the db it was storing XXX
	-- the lua table was unaffected until the bot was reloaded or restarted when it would load the teleports from the db
	
	-- now we will re-save all the teleports to the db correctly
	for k,v in pairs(teleports) do
		conn:execute("UPDATE teleports SET x = " .. v.x .. ", y = " .. v.y .. ", z = " .. v.z .. ", dx = " .. v.dx .. ", dy = " .. v.dy .. ", dz = " .. v.dz .. " WHERE name = '" .. escape(k) .. "'")
	end
	
	irc_chat(server.ircMain, "Check teleports in database.  Should be correct now.")
end

function downloadTest()
	os.execute("wget botman.nz/stable/version.txt")
end
