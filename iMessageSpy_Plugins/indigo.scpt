-- This is a sample plugin file. It must be compiled as a script (.scpt) and placed @
-- ~/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins

-- This script provides a narrow avenue of usefulness when using Indigo.
-- The commands are generic enough that they work for anyone, but to 
-- get more power out of this you will need to create your own code to do 
-- things you want. :) I'm still trying to develop generic methods for
-- performing other common tasks.

on MainRoutine(pName, theHandle, theCmd, theArgs, isAdmin)
	if isAdmin is not true then return ""
	if theCmd is "on" or theCmd is "off" then
		return changeDeviceState(theCmd, theArgs)
	else if theCmd is "ag" then
		return execActionGropup(theArgs)
	else if theCmd is "dim" then
		if (count words of theArgs) is less than 2 then
			return "Invalid Usage. Must send " & pName & " dim <number> <camera name>"
		end if
		set AppleScript's text item delimiters to space
		-- Split the brightness from the device name in theArgs.		
		set theBrightness to (the first text item of theArgs)
		set theDevice to (text items 2 thru -1 of theArgs as string)
		set AppleScript's text item delimiters to ""
		return changeDeviceState(theBrightness, theDevice)
	else if theCmd is "var" then
		return manageVars(theArgs)
	else if theCmd is "find" then
		return findDevice(theArgs, "text")
	else if theCmd is "findag" then
		return findAG(theArgs, "text")
	else if theCmd is "help" then
		return HelpDialog(pName, isAdmin)
	end if
	-- No known command was given, return our help line.
	return "Invalid sub-command provided." & return & my HelpLine(pName, isAdmin)
end MainRoutine

-- Searches Indigo for any device containing/matching findDev.
on findDevice(findDev, returnType)
	set returnDevs to {}
	tell application "IndigoServer"
		set Devs to devices
		repeat with Dev in Devs
			if findDev is in (name of Dev) then
				-- if they match, add them to the list.
				set the end of returnDevs to name of Dev
			end if
		end repeat
	end tell
	if returnType is "list" then return returnDevs
	-- If type is not a list, we return text for humans.
	if (count of returnDevs) is less than 1 then
		return "No devices matching '" & findDev & "' were located."
	end if
	set theResponse to "Devices matching '" & findDev & "' -> "
	set i to 0
	repeat with loopDev in returnDevs
		set i to i + 1
		set theResponse to theResponse & "'" & loopDev & "'"
		if i is not (count returnDevs) then
			set theResponse to theResponse & ", "
		else
			set theResponse to theResponse & "."
		end if
	end repeat
	return theResponse
end findDevice

-- Searches Indigo for any action group containing/matching findAG.
on findAG(findAG, returnType)
	set returnAGs to {}
	tell application "IndigoServer"
		set AGs to action groups
		repeat with AG in AGs
			if findAG is in (name of AG) then
				-- if they match, add them to the list.
				set the end of returnAGs to name of AG
			end if
		end repeat
	end tell
	if returnType is "list" then return returnAGs
	-- If type is not a list, we return text for humans.
	if (count of returnAGs) is less than 1 then
		return "No action groups matching '" & findAG & "' were located."
	end if
	set theResponse to "Action Groups matching '" & findAG & "' -> "
	set i to 0
	repeat with loopAG in returnAGs
		set i to i + 1
		set theResponse to theResponse & "'" & loopAG & "'"
		if i is not (count returnAGs) then
			set theResponse to theResponse & ", "
		else
			set theResponse to theResponse & "."
		end if
	end repeat
	return theResponse
end findAG

on execActionGropup(AG)
	if AG is not in findAG(AG, "list") then
		return "Action Group '" & AG & "' was not found."
	end if
	try
		tell application "IndigoServer" to execute group AG
	on error
		return "There was an error executing the action group: " & AG
	end try
	return "Executed Action Group: " & AG
end execActionGropup

-- Get or Set variables.
on manageVars(InputData)
	-- InputData may be a string of one of these: 1. empty, 2. a variable, 3. a variable and a new value.
	if (count words of InputData) is 1 then
		-- display value of a single variable
		set theResponse to "Value of variable '" & InputData & "' is: "
		try
			tell application "IndigoServer" to set theResponse to theResponse & value of variable InputData
		on error
			return "Error getting data for variable " & InputData & " -> It may not exist?"
		end try
	else if (count words of InputData) is 0 then
		set theResponse to "Values of all variables:" & return
		try
			tell application "IndigoServer" to repeat with loopVar in variables
				set theResponse to theResponse & name of loopVar & " = " & value of loopVar & return
			end repeat
		on error
			return "Error retrieving variable info from Indigo."
		end try
	else
		-- We are setting a variable to a value here.
		set varName to the first word of InputData
		set AppleScript's text item delimiters to space
		try
			set varValue to (text items 2 thru -1 of InputData as string)
			tell application "IndigoServer" to set value of variable varName to varValue
		on error
			return "Error setting value of variable " & varName & "."
		end try
		set AppleScript's text item delimiters to ""
		set theResponse to "Set value of variable " & varName & " to: " & varValue
	end if
	return theResponse
end manageVars

-- Turn a thing on or off or set brightness.
on changeDeviceState(State, Dev)
	if Dev is not in findDevice(Dev, "list") then
		return "Device '" & Dev & "' was not found."
	end if
	try
		if State is "on" then
			tell application "IndigoServer" to turn on Dev
			return "Turned device " & Dev & " on."
		else if State is "off" then
			tell application "IndigoServer" to turn off Dev
			return "Turned device " & Dev & " off."
		end if
	on error
		return "Error turning device " & Dev & " " & State & "."
	end try
	-- If a number was passed in instead of on or off, change brightness.
	try
		set State to State as number
	on error
		return "Error, state not understood: " & State
	end try
	if State is less than 0 or State is greater than 100 then
		return "Brightness must be between 0 and 100."
	end if
	try
		tell application "IndigoServer" to dim Dev to State
		return "Set brightness for device " & Dev & " to " & State & "%."
	on error
		return "Error setting brightness for device " & Dev & "."
	end try
	return "An unknown error occurred with your command."
end changeDeviceState

on HelpDialog(pName, isAdmin)
	set Res to pName & " help - Displays this help message." & return
	set Res to Res & pName & " on <device name> - Turn a device on." & return
	set Res to Res & pName & " off <device name> - Turn a device off." & return
	set Res to Res & pName & " ag <action group> - Execute an action group." & return
	set Res to Res & pName & " dim <amount> <device name> - Change a device's brightness. Amount must be between 1 and 100." & return
	set Res to Res & pName & " find <term> - Case insensitive search for devices that contain <term> in their name." & return
	set Res to Res & pName & " findag <term> - Case insensitive search for actions groups that contain <term> in their name." & return
	set Res to Res & pName & " var [variable] [value] - Display value of all variables or [variable] if provided. If [value] is also provided, set the variable to this value." & return
end HelpDialog

on HelpLine(pName, isAdmin)
	if isAdmin is not true then return ""
	return pName & " - Controls things in Indigo. Send 'indigo help' for more info!"
end HelpLine


