Hi!

The lua files in the scripts folder contains most of the bot's coding.  You can make changes to it but be aware that if you enable automatic bot updates, all of this code will be replaced every time I release new code to the branch that your bot is watching.

Above the scripts folder you will find a folder called custom with 2 scripts in it, customIRC.lua and gmsg_custom.lua.  If you want to code your own commands for IRC or ingame, you can safely place them here.  They are executed early so you can use them to block or replace existing bot commands or add new stuff.  The custom folder is not inside the scripts folder so bot updates won't replace your code here.

By default your bot will watch the stable branch of my code releases but it won't automatically update.  It will alert you and tell you what command to type to update manually.  I maintain several code branches, stable, testing, trial, and bleeding.   Your bot can safely switch between any of them and back again any time.  The stable branch is updated less often so you won't normally see a lot of bot updates.

If you want to switch branches, the ingame command for that is /set update branch stable
Follow that with /update code.  After a short delay your bot should announce that it has been updated.  If you already have the latest code from your chosen branch, you might not see a response ingame but the bot will report to IRC.

And now some notes about the code files and folders..

The chat folder contains code organised into sections with commands that trigger from ingame chat from players.  The file, gmsg_functions.lua contains the chat parser and is the first script called when the bot receives a chat line from the server.  More on that in another readme in the chat folder.

The timers folder contains scripts that are triggered on timers that you will find in the bot's profile.  The main purpose of these timers is to pace various bot activities so that it doesn't flood the server too quickly and to pace spawning of zombies and displaying of messages to players and IRC.

The triggers folder contains scripts that trigger when the bot detects certain texts coming from the server via telnet.  The most noteable of these is match_all, player_info and gmsg_functions (which lives in the chat folder).

The remaining scripts are a collection of various functions and features organised into named files.  There are many important scripts here including edit_me, startup_bot, functions, core_functions, mysql, and scripts for processing bot commands from IRC.

Most files contain debug lines that are disabled by default.  Near the top you will find debug = false.  If you want to debug the bot's code, enable this for any code that you want to test.  You will also want to turn on debug output to Mudlet's various windows.  To do that, from IRC type debug on.  Note that you will need to turn it on after each time that you reload the bot's code since it will disable itself to improve performance.  Too much debugging really slows the bot down, especially in the busier files such as match_all.

Once enabled, you will see debug messages in Mudlet's windows.  It is also possible to have it send debug to the watch channel in IRC if you add lines to the code such as dbugi("some debug text here").  If there is a fault in the bot's code, it will typically stop executing at the line with the fault.  You can use the debug info which typically displays a line number and the function name to help narrow down to just above the line or code block containing the fault.  Most of the time the fault will be due to some missing value in a variable being tested.  The bot has several automatic fixes that are applied when needed and/or on timers but these can't fix everything, just common issues.



