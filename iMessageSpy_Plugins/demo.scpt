-- This is a sample plugin file. It must be compiled as a script (.scpt) and placed @
-- ~/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins

on MainRoutine(pName, theHandle, theCmd, theArgs, isAdmin)
	set Reply to theHandle & " -> Hello! You can create a plugin like this."
	if theArgs is not "" then set Reply to nl(Reply, "You sent: " & theCmd & " " & theArgs)
	if isAdmin then set Reply to nl(Reply, "You are an admin, so yeah, that's cool.")
	return Reply
end MainRoutine

-- Return a string with return and another string
on nl(string1, string2)
	return string1 & return & string2
end nl

on HelpLine(pName, isAdmin)
	return pName & " - This is just a " & pName & " plugin!"
end HelpLine


