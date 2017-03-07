-- This is a sample plugin file. It must be compiled as a script (.scpt) and placed @
-- /Users/cartcrafter/Library/Application Scripts/com.apple.iChat/SecuritySpy_Plugins

on MainRoutine(theHandle, theArgument, isAdmin)
	set theResponse to theHandle
	set theResponse to theResponse & " -> Hello! You can create a plugin like this."
	if theArgument is not "" then
		set theResponse to theResponse & return & "You also sent: " & theArgument
	end if
	if isAdmin then
		set theResponse to theResponse & return & "You are an admin, so yeah, that's cool."
	end if
	return theResponse
end MainRoutine

