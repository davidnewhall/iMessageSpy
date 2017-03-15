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

-- Set to false if you don't want the text "Motion Detected! Camera ..." I always set to false.
property SendCameraName : true
-- Temporary location used to save images. Try (POSIX path of (path to desktop)) here.
property TempFolder : "/tmp"
-- Delay helps prevent duplicate images. If you get duplicate images, increase this. 0.7 should be max.
property ImageDelay : 0.1
-- Must match the file name used in iMessageSpy.applescript (don't just change it here).
property PlistFileName : "com.cartcrafter.iMessageSpy.plist"


-- Change Porch to a real camera name to test this in Script Editor
property TestCam : "Porch"

on run arg
	if (count of arg) is not 2 then set arg to {0, TestCam}
	set Camera to item 2 of arg -- item 1 is the cam number.
	-- Once Messages.app gets sanboxed, this is the new location of the plist file we create.
	-- Luckily, SecuritySpy is not sandboxed (yet).
	set plistFilePath to (path to home folder as text) & "Library:Containers:com.apple.iChat:Data:Library:Preferences:" & PlistFileName
	if not (exists file plistFilePath of application "System Events") then
		set plistFilePath to (path to home folder as text) & "Library:Preferences:" & PlistFileName
		if not (exists file plistFilePath of application "System Events") then return
	end if
	-- This next line opens the file (r/w). Not very obvious, huh?
	tell application "System Events" to tell property list file plistFilePath to tell contents
		-- This next line checks if any handles exist in the file. If none, everyone unsubscribed.
		if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return
		-- Save the plist data into an array.
		set Subscribers to value of every property list item of property list item "Subscribers" as list
	end tell
	my notifySubscribers(Camera, Subscribers)
	try -- Just in case Messages is "not running"
		tell application "Messages" to close windows
	end try
end run

on notifySubscribers(Camera, Subscribers)
	set ImageFile to "" -- Used later to save our image file, should we need to capture one.
	-- Loop thru each subscriber and check if they subscribe to this camera.
	-- This pulls an array (of subscriber data) out of the larger array.
	repeat with Subscriber in Subscribers
		if (ignored of Subscriber is false) then -- They're ignored, go to next subscriber.
			-- Check each camera. This data structure needs to be changed to be better.
			repeat with loopCam in cameras of Subscriber
				if (Camera is camName of loopCam) and (startat of loopCam < (current date)) then
					-- We have the right camera, and it's not stopped.
					if ImageFile is "" then set ImageFile to my saveImage(Camera)
					-- The handle is the iMessage name.
					-- A phone number or email address in most cases.
					my sendImage(handle of Subscriber, ImageFile, Camera)
				end if
			end repeat
		end if
	end repeat
end notifySubscribers

on saveImage(Camera)
	-- This will overwrite the file every time.
	set theFile to TempFolder & "/securityspy_imessage_file_" & Camera & ".jpg"
	tell application "SecuritySpy" to capture image as theFile camera name Camera with overwrite
	delay ImageDelay
	-- This changes the variable into something iMessage can use.
	return (POSIX file theFile)
end saveImage

on sendImage(Subscriber, ImageFile, Camera)
	try -- Just in case Messages is "not running"
		tell application "Messages"
			-- Best trick to send an iMessage that I've come across. Seems to work every time. More tips are welcomed.
			send ImageFile to buddy Subscriber of (1st service whose service type = iMessage)
			if SendCameraName is false then return
			delay 0.1
			send "Motion Detected! Camera " & Camera & ". Reply \"stop\" to stop and \"help\" for other options." to buddy Subscriber of (1st service whose service type = iMessage)
		end tell
	end try -- What can securityspy do with an error? need a 'log' command to fire an event log entry.
end sendImage
