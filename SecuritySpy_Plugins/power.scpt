-- This is a sample plugin file. It must be compiled as a script (.scpt) and placed @
-- /Users/cartcrafter/Library/Application Scripts/com.apple.iChat/SecuritySpy_Plugins
-- Code is thanks to Andreas Echavez (@oceanplexian)

on MainRoutine(theHandle, theArgument, isAdmin)
	if not isAdmin then return ""
	-- This provides power/battery and runtime information 
	do shell script "pmset -g everything | grep Cycles ; true"
	set powerstatus to the result
	set theResponse to "Power Status:" & powerstatus
	return theResponse
end MainRoutine

