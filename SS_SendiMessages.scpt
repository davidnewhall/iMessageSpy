(* ***************************************************
**   --== iMessageSpy ==--
** File: SS_SendiMessages.scpt
** This script is designed to be used with SecuritySpy.app
** and Messages.app. There is another script that must be used as
** your Messages.app AppleScript handler.
** Copy this script to:
** ~/Documents/SecuritySpy/Scripts/
** Copy the other script to:
** ~/Library/Application Scripts/com.apple.iChat/
** Set your camera's Actions to run this script.
** (hint: it's in the SecuritySpy's camera settings under Actions)
** This script will do nothing by itself. You must subscribe to
** your cameras using the SecuritySpy Remote Control script.
** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **
** Download the latest files at:
** https://github.com/davidnewhall/iMessageSpy
*************************************************** *)

on run arg
	set plistFilePath to (path to home folder as text) & "Library:Preferences:com.cartcrafter.SSHelper.plist"
	if not (exists file plistFilePath of application "Finder") then
		return
	end if
	set camName to item 2 of arg
	set Subscribers to {}
	tell application "System Events"
		tell property list file plistFilePath
			tell contents
				if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return
				set allSubs to value of every property list item of property list item "Subscribers" as list
				-- Loop thru each subscriber and check if they subscribe to this camera.
				repeat with i from 1 to count allSubs
					set loopSub to (item i of allSubs)
					if (camName is in cameras of loopSub) and (ignored of loopSub is false) and (startat of loopSub < (current date)) then
						set Subscribers to Subscribers & {handle of loopSub}
					end if
				end repeat
			end tell
		end tell
	end tell
	if (count Subscribers) is 0 then return
	
	set theFile to "/tmp/securityspy_imessage_file_" & camName & ".jpg"
	tell application "SecuritySpy" to capture image as theFile camera name camName with overwrite
	
	set theFile to (POSIX file theFile)
	tell application "Messages"
		repeat with Subscriber in Subscribers
			set targetBuddy to buddy Subscriber of (1st service whose service type = iMessage)
			send "Motion Detected! Camera " & camName & ". Reply \"stop\" to stop messages for 10 minues." to targetBuddy
			send theFile to targetBuddy
		end repeat
		close windows
	end tell
end run
