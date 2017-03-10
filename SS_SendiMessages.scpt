(* ***************************************************
**   --== iMessageSpy ==--
** File: SS_SendiMessages.scpt
** This script is designed to be used with SecuritySpy.app
** and Messages.app. There is another script that must be used as
** your Messages.app AppleScript handler.
** Copy this script to:
** ~/Documents/SecuritySpy/Scripts/
** Set your camera's Actions to run this script.
** (hint: it's in the SecuritySpy's camera settings under Actions)
** This script will do nothing by itself. You must subscribe to
** your cameras using the iMessageSpy (Messages.app) script.
** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **
** Download the latest files at:
** https://github.com/davidnewhall/iMessageSpy
*************************************************** *)

-- You can use something like the below to test this in Script Editor
-- set arg to {0, "Porch"}

on run arg
	-- This delay will help prevent duplicate images. If you tend to get duplicate images, increase the delay. 0.7 should be your max.
	set imageDelay to 0.1
	-- Set this to false if you do not want the text "Motion Detected! Camera ..." with your images. I always set to false.
	set sendCameraName to true
	
	-- Once Messages.app gets sanboxed, this is the new location of the plist file we create. Luckily, SecuritySpy is not sandboxed (yet).
	set plistFilePath to (path to home folder as text) & "Library:Containers:com.apple.iChat:Data:Library:Preferences:com.cartcrafter.iMessageSpy.plist"
	if not (exists file plistFilePath of application "Finder") then
		set plistFilePath to (path to home folder as text) & "Library:Preferences:com.cartcrafter.iMessageSpy.plist"
		if not (exists file plistFilePath of application "Finder") then
			return
		end if
	end if
	set camName to item 2 of arg
	set Subscribers to {}
	tell application "System Events"
		tell property list file plistFilePath
			tell contents
				-- This next line checks if any handles exist in the file. It can happen if everyone unsubscribes, after at least 1 person subscribed.
				if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return
				-- AppleScript makes creating arrays so easy.
				set allSubs to value of every property list item of property list item "Subscribers" as list
				-- Loop thru each subscriber and check if they subscribe to this camera.
				repeat with i from 1 to count allSubs
					-- This pulls an array (of subscriber data) out of the larger array.
					set loopSub to (item i of allSubs)
					-- Do they subscribe to this camera? Are they ignored? Is there a stop timer in place? yes, no, no, go
					repeat with loopCam in cameras of loopSub
						if (camName is camName of loopCam) and (ignored of loopSub is false) and (startat of loopCam < (current date)) then
							-- The handle is the actual iMessage name. A phone number or email address in most cases.
							set Subscribers to Subscribers & {handle of loopSub}
						end if
					end repeat
				end repeat
			end tell
		end tell
	end tell
	if (count Subscribers) is 0 then return
	
	-- This will overwrite the file every time.
	set theFile to "/tmp/securityspy_imessage_file_" & camName & ".jpg"
	tell application "SecuritySpy" to capture image as theFile camera name camName with overwrite
	delay imageDelay
	-- This changes the variable into something iMessage can use.
	set theFile to (POSIX file theFile)
	-- This is the Subscribers array we built previously.
	repeat with Subscriber in Subscribers
		tell application "Messages"
			-- Best trick to send an iMessage that I've come across. Seems to work every time. More tips are welcomed.
			set targetBuddy to buddy Subscriber of (1st service whose service type = iMessage)
			if sendCameraName is true then
				send "Motion Detected! Camera " & camName & ". Reply \"stop\" to stop messages for 10 minues." to targetBuddy
				delay 0.1
			end if
			send theFile to targetBuddy
		end tell
	end repeat
	tell application "Messages" to close windows
end run
