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

-- Set this to false if you do not want the text "Motion Detected! Camera ..." with your images. I always set to false.
property SendCameraName : true
-- This delay will help prevent duplicate images. If you tend to get duplicate images, increase the delay. 0.7 should be your max.
property ImageDelay : 0.1

-- Change Porch to a real camera name to test this in Script Editor
property testCam : "Porch"

on run arg
	if (count of arg) is not 2 then set arg to {0, testCam}
	set camName to item 2 of arg -- item 1 is the cam number.
	-- Once Messages.app gets sanboxed, this is the new location of the plist file we create.
	-- Luckily, SecuritySpy is not sandboxed (yet).
	set plistFilePath to (path to home folder as text) & "Library:Containers:com.apple.iChat:Data:Library:Preferences:com.cartcrafter.iMessageSpy.plist"
	if not (exists file plistFilePath of application "Finder") then
		set plistFilePath to (path to home folder as text) & "Library:Preferences:com.cartcrafter.iMessageSpy.plist"
		if not (exists file plistFilePath of application "Finder") then
			return
		end if
	end if
	
	tell application "System Events"
		tell property list file plistFilePath
			tell contents
				-- This next line checks if any handles exist in the file. It can happen if everyone unsubscribes, after at least 1 person subscribed.
				if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return
				set ImageFile to "" -- Used lated to save our image file, should we need to capture one.
				-- AppleScript makes creating arrays so easy.
				set allSubs to value of every property list item of property list item "Subscribers" as list
				-- Loop thru each subscriber and check if they subscribe to this camera.
				-- This pulls an array (of subscriber data) out of the larger array.
				repeat with loopSub in allSubs
					if (ignored of loopSub is false) then -- They're ignored, go to next subscriber.
						-- Check each camera. This data structure needs to be changed to be better.
						repeat with loopCam in cameras of loopSub
							if (camName is camName of loopCam) then -- they have a subscription
								if (startat of loopCam < (current date)) then -- it's not stopped.
									-- The handle is the actual iMessage name. A phone number or email address in most cases.
									if ImageFile is equal to "" then set ImageFile to my saveImage(camName)
									my sendImage(handle of loopSub, ImageFile, camName)
								end if
							end if
						end repeat
					end if
				end repeat
			end tell
		end tell
	end tell
	try -- Just in case Messages is "not running"
		tell application "Messages" to close windows
	end try
end run

on saveImage(camName)
	-- This will overwrite the file every time.
	set theFile to "/tmp/securityspy_imessage_file_" & camName & ".jpg"
	tell application "SecuritySpy" to capture image as theFile camera name camName with overwrite
	delay ImageDelay
	-- This changes the variable into something iMessage can use.
	return (POSIX file theFile)
end saveImage

on sendImage(Subscriber, ImageFile, camName)
	try -- Just in case Messages is "not running"
		tell application "Messages"
			-- Best trick to send an iMessage that I've come across. Seems to work every time. More tips are welcomed.
			send ImageFile to buddy Subscriber of (1st service whose service type = iMessage)
			if SendCameraName is true then
				delay 0.1
				send "Motion Detected! Camera " & camName & ". Reply \"stop\" to stop and \"help\" for other options." to buddy Subscriber of (1st service whose service type = iMessage)
			end if
		end tell
	end try -- What can securityspy do with an error? need a 'log' command to fire an event log entry.
end sendImage
