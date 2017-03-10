-- This is a sample plugin file. It must be compiled as a script (.scpt) and placed @
-- ~/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins
-- This probably only works on a MacBook (Pro/Air/Etc) as your SecuritySpy server.

on MainRoutine(pName, theHandle, theCmd, theArgs, isAdmin)
	set theResponse to ""
	if theCmd is "screen" and isAdmin then
		-- Turn the display on or off (by adjusting the brightness).
		if (theArgs is not "on" and theArgs is not "off") then
			set theResponse to "Usage: " & return & my HelpLine(pName, isAdmin)
		else if theArgs is "on" then
			set theResponse to my displayBrightness(0.8)
		else
			set theResponse to my displayBrightness(0)
		end if
		
		-- This code is thanks to Andreas Echavez (@oceanplexian)
	else if theCmd is "power" then
		-- This provides power/battery and runtime information
		do shell script "pmset -g everything | grep Cycles ; true"
		set powerstatus to the result
		set theResponse to "Power Status:" & powerstatus
		
	else -- no sub command provided.
		set theResponse to "Usage: " & return & my HelpLine(pName, isAdmin)
	end if
	return theResponse
end MainRoutine

on HelpLine(pName, isAdmin)
	-- `power` can be used by non-admins, `screen` cannot.
	set theResponse to pName & " power - Provides power/battery and runtime information."
	if isAdmin then
		set theResponse to theResponse & return & pName & " screen <on|off> - Sets host's screen brightness."
	end if
	return theResponse
end HelpLine

-- brightness should be between 0 and 1.
on displayBrightness(brightness)
	tell application "System Preferences"
		activate
		reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
		tell application "System Events"
			delay 0.3
			set value of slider 1 of group 1 of tab group 1 of window 1 of process "System Preferences" to brightness
		end tell
		quit
	end tell
	return {"Displayed brightness set to " & (round (brightness * 100)) & "%"}
end displayBrightness
