(* ***************************************************
**   --== iMessageSpy ==--
** File: iMessageSpy.applescript
** This script is designed to be used with Messages.app
** and SecuritySpy.app. There is another script that must
** be used as an Action for your cameras in SecuritySpy.
** Copy this script to:
** ~/Library/Application Scripts/com.apple.iChat/
** Set your AppleScript handler in Messages.app to this script.
** (hint: it's in the app's General Preferences)
** Send "help" or "pics" via iMessage. This only works with
** iMessage and SecuritySpy must be running with 1 or more cam.
** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** ** **
** Download the latest package at:
** https://github.com/davidnewhall/iMessageSpy
*************************************************** *)

using terms from application "Messages"
	on getPicsFromSS(getCamera)
		tell application "SecuritySpy" to set CameraNames to (get camera names)
		if getCamera is "" then
			-- Getting pictures from all cameras.
			set theResponse to {}
			set i to 0
			set camCount to count CameraNames
			repeat with CameraLoop in CameraNames
				set i to i + 1
				set theFile to "/tmp/securityspy_imessage_file_" & CameraLoop & ".jpg"
				try
					tell application "SecuritySpy" to capture image as theFile camera name CameraLoop with overwrite
					set the end of theResponse to POSIX file theFile
				on error
					-- This may happen if the camera is diconnected. SecuritySpy throws an error.
					set the end of theResponse to "Error with camera " & CameraLoop
				end try
			end repeat
		else if getCamera is not in CameraNames then
			set theResponse to "Camera not found: " & getCamera & return
			set theResponse to theResponse & "Use \"cams\" to see the camera names. Send \"pics\" to see a picture from each camera."
		else
			-- Just getting a picture from one camera.
			set getCamera to my CorrectCase(getCamera, CameraNames)
			set theFile to "/tmp/securityspy_imessage_file_" & getCamera & ".jpg"
			try
				tell application "SecuritySpy" to capture image as theFile camera name getCamera with overwrite
				set theResponse to POSIX file theFile
			on error
				-- This may happen if the camera is diconnected. SecuritySpy throws an error.
				set the end of theResponse to "Error with camera " & getCamera
			end try
		end if
		return theResponse
	end getPicsFromSS
	
	on CorrectCase(this_item, this_list)
		repeat with i from 1 to the count of this_list
			if item i of this_list is this_item then return item i of this_list
		end repeat
		return this_item
	end CorrectCase
	
	on SubscribeCam(subCam, subName, subHandle)
		global plistFilePath
		-- The code in this if-statements creates the initial, empty property list file.
		-- The code that follows re-writes the file with real data. All of this took a really long time to figure out.
		if not (exists file plistFilePath of application "System Events") then
			try
				-- This next line is a stupid hack required on Yosemite.
				do shell script "defaults write " & (POSIX path of plistFilePath) & " Subscribers -boolean true"
				delay 0.2
				tell application "System Events"
					set plistdir to make new property list item with properties {kind:record}
					set plistfile to make new property list file with properties {contents:plistdir, name:plistFilePath}
					make new property list item at end of property list items of contents of plistfile with properties {kind:list, name:"Subscribers"}
				end tell
			end try
			delay 0.2
		end if
		
		tell application "SecuritySpy" to set allCams to (get camera names)
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						-- If we get here, it means the file already has a (possibly unsubscribed) Subscriber.
						-- It could be the same subscriber as subHandle, or a different handle entirely.
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set subExists to false
						set newSubList to {}
						-- Loop thru each subscriber from the plist file and recreate the data into newSubList
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								-- We found the handle we're after, now compare this new camera to what they currently have.
								set subExists to true
								if subCam is "*" then
									set allCams to my MakeCamList(allCams)
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:subName, cameras:allCams}
									set theResponse to "You are now subscribed to all " & (count allCams) & " camera(s)."
								else
									set gotIt to false
									repeat with loopCam in cameras of loopSub
										if subCam as string is equal to camName of loopCam as string then
											set theResponse to "You are already subscribed to this camera."
											set gotIt to true
											-- Don't do anything, just append the data and save it without changes.
											set newSubList's end to allSubs's item i
										end if
									end repeat
									if gotIt is false then
										set subCam to my CorrectCase(subCam, allCams)
										-- Add new camera to previous subscriber.
										set newCams to my AddCamList(cameras of loopSub, subCam)
										set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:subName, cameras:newCams}
										set theResponse to "You are now subscribed to " & (count newCams) & " cameras."
									end if
								end if
							else
								-- Just keep the record, not the handle we're after.
								set newSubList's end to allSubs's item i
							end if
						end repeat
						-- This gets set true if we find the handle in the block of code above, therefore this gets skipped.
						if subExists is false then
							-- New subscriber, but not the first, so no admin flag.
							if subCam is "*" then
								set partialResponse to "all " & (count allCams) & " cameras."
							else
								set partialResponse to "your first camera."
								set subCam to my CorrectCase(subCam, allCams)
							end if
							set subCam to my MakeCamList(subCam)
							set newSubList's end to {handle:subHandle, admin:false, ignored:false, contact:subName, cameras:subCam}
							set theResponse to "You have been successfully subscribed to " & partialResponse
						end if
						-- This is where the plist file is re-written with this new subscription appended.
						set value of property list item "Subscribers" to newSubList
					else
						-- First user, create with admin flag. We only hit this code once in real-world use.
						if subCam is "*" then
							set subCam to allCams
						else
							set subCam to my {CorrectCase(subCam, allCams)}
						end if
						set subCam to my MakeCamList(subCam)
						-- This is what actually re-writes the plist file for the first time and creates real data.
						set value of property list item "Subscribers" to (previousValue & {{handle:subHandle, admin:true, ignored:false, contact:subName, cameras:subCam}})
						set theResponse to "You have subscribed to your first camera, and since you are the first subscriber you have been given admin powers. Send \"help\" for your commands."
					end if
				end tell
			end tell
		end tell
		return theResponse
	end SubscribeCam
	
	on MakeCamList(allCams)
		set camList to {}
		set startTime to (current date)
		repeat with loopCam in allCams
			set the end of camList to {camName:loopCam, startat:startTime}
		end repeat
		return camList
	end MakeCamList
	on AddCamList(startList, camName)
		set startTime to current date
		set the end of startList to {camName:camName, startat:startTime}
		return startList
	end AddCamList
	
	on unSubscribeCam(subCam, subHandle)
		global plistFilePath
		if not (exists file plistFilePath of application "System Events") then
			return "There are no subscribers, including you."
		end if
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set subExists to false
						set newSubList to {}
						-- Loop thru each subscriber and recreate the data into newSubList
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								set subExists to true
								if subCam is "*" then
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:contact of loopSub, cameras:{}}
									set theResponse to "You have been successfully ubsubscribed from all cameras"
								else if (count cameras of loopSub) is 0 then
									return "You are not subscribed to any cameras."
								else
									set gotIt to false
									set newCams to {}
									repeat with loopCam in cameras of loopSub
										if camName of loopCam as string is not equal to subCam as string then
											set the end of newCams to loopCam
										else
											set gotIt to true
											set subCam to camName of loopCam
										end if
									end repeat
									if gotIt is false then
										-- we don't do anything, no updates, nothing. bail out.
										return "You are not subscribed to " & subCam
									end if
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:contact of loopSub, cameras:newCams}
									set theResponse to "You have been successfully ubsubscribed from " & subCam & return & "You are now subscribed to " & (count newCams) & " cameras."
								end if
							else
								-- just keep the record, not the handle we're after.
								set newSubList's end to allSubs's item i
							end if
						end repeat
						if subExists is false then
							-- new subscriber, but not the first, so no admin flag.
							return "You have never subscribed to any cameras."
						end if
						-- This is what actually re-writes the plist file.
						set value of property list item "Subscribers" to newSubList
					else
						return "You have never subscribed to any cameras."
					end if
				end tell
			end tell
		end tell
		return theResponse
	end unSubscribeCam
	
	on changeIgnoreStatus(subHandle)
		global plistFilePath
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set newSubList to {}
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								if ignored of loopSub is true then
									set newSubList's end to {handle:subHandle, admin:false, ignored:false, contact:contact of loopSub, cameras:{}}
									set theResponse to subHandle & " is no longer being ignored."
								else
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:true, contact:contact of loopSub, cameras:{}}
									set theResponse to subHandle & " is now being ignored."
								end if
							else
								set newSubList's end to allSubs's item i
							end if
						end repeat
						set value of property list item "Subscribers" to newSubList
					end if
				end tell
			end tell
		end tell
		return theResponse
	end changeIgnoreStatus
	
	on changeAdminStatus(subHandle)
		global plistFilePath
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set newSubList to {}
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								if admin of loopSub is true then
									set newSubList's end to {handle:subHandle, admin:false, ignored:ignored of loopSub, contact:contact of loopSub, cameras:cameras of loopSub}
									set theResponse to subHandle & " is no longer an admin."
								else
									set newSubList's end to {handle:subHandle, admin:true, ignored:false, contact:contact of loopSub, cameras:cameras of loopSub}
									set theResponse to subHandle & " is now an admin."
								end if
							else
								set newSubList's end to allSubs's item i
							end if
						end repeat
						set value of property list item "Subscribers" to newSubList
					end if
				end tell
			end tell
		end tell
		return theResponse
	end changeAdminStatus
	
	on stopNotices(Mins, camName, subHandle)
		global plistFilePath
		set startTime to (current date) + (Mins * minutes)
		if not (exists file plistFilePath of application "System Events") then
			return "There are no subscribers, including you. You should not be receiving notices."
		end if
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set subExists to false
						set newSubList to {}
						-- Loop thru each subscriber and recreate the data into newSubList
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								set subExists to true
								if (count cameras of loopSub) is 0 then
									return "You are not subscribed to any cameras. You should not be receiving notices."
								else
									set newCamList to {}
									set gotIt to false
									repeat with loopCam in cameras of loopSub
										if camName is "*" or camName in loopCam is camName then
											set gotIt to true
											set the end of newCamList to {camName:camName in loopCam, startat:startTime}
											if camName is not "*" then set camName to my CorrectCase(camName, {camName in loopCam})
										else
											-- Leave it untouched.
											set the end of newCamList to loopCam
										end if
									end repeat
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:contact of loopSub, cameras:newCamList}
									if gotIt is false then
										set theResponse to "You are not subscribed to the camera " & camName
									else if camName is "*" then
										set theResponse to "You will not receive any more notices (from any camera) for at least " & Mins & " minutes."
									else
										set theResponse to "You will not receive any more notices from camera " & camName & " for at least " & Mins & " minutes."
									end if
								end if
							else
								-- just keep the record, not the user we're after.
								set newSubList's end to allSubs's item i
							end if
						end repeat
						if subExists is false then
							-- new subscriber, but not the first, so no admin flag.
							set theResponse to "You have never subscribed to any cameras. You should not be receiving notices."
						end if
						set value of property list item "Subscribers" to newSubList
					else
						set theResponse to "You have never subscribed to any cameras. You should not be receiving notices."
					end if
				end tell
			end tell
		end tell
		return theResponse
	end stopNotices
	
	on getAdmins(plistFilePath)
		set Admins to {}
		try
			tell application "System Events"
				tell property list file plistFilePath
					tell contents
						if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return Admins
						set allSubs to value of every property list item of property list item "Subscribers" as list
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if (admin of loopSub is true) then
								set Admins to Admins & {handle of loopSub}
							end if
						end repeat
					end tell
				end tell
			end tell
		end try
		return Admins
	end getAdmins
	
	on getAllSubs(returnFullRecord)
		global plistFilePath
		set Subscribers to {}
		if not (exists file plistFilePath of application "System Events") then return Subscribers
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return Subscribers
					set allSubs to value of every property list item of property list item "Subscribers" as list
					repeat with i from 1 to count allSubs
						set loopSub to (item i of allSubs)
						if returnFullRecord is true then
							set the end of Subscribers to {handle of loopSub, contact of loopSub, ignored of loopSub, admin of loopSub, cameras of loopSub}
						else
							set the end of Subscribers to (handle of loopSub)
						end if
					end repeat
				end tell
			end tell
		end tell
		return Subscribers
	end getAllSubs
	
	on getIgnores(plistFilePath)
		set Ignores to {}
		try
			tell application "System Events"
				tell property list file plistFilePath
					tell contents
						if not (exists property list item "handle" of every property list item of property list item "Subscribers") then return Ignores
						set allSubs to value of every property list item of property list item "Subscribers" as list
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if (ignored of loopSub is true) then
								set Ignores to Ignores & {handle of loopSub}
							end if
						end repeat
					end tell
				end tell
			end tell
		end try
		return Ignores
	end getIgnores
	
	on message received theMessage from theBuddy for theChat
		global plistFilePath
		set theHandle to handle of theBuddy
		set plistFilePath to (path to home folder as text) & "Library:Preferences:com.cartcrafter.iMessageSpy.plist"
		-- It's unfotunate the plist is looped twice, once for each of these calls. Will be nice to reduce it to one call..
		if not (exists file plistFilePath of application "System Events") then
			set thisHandleIsAdmin to true
			set allAdmins to {}
		else
			if theHandle is in getIgnores(plistFilePath) then return
			set allAdmins to getAdmins(plistFilePath)
			if theHandle is in allAdmins then
				set thisHandleIsAdmin to true
			else
				set thisHandleIsAdmin to false
			end if
		end if
		--Initialize an empty response.
		set theResponse to {}
		-- The command is the first word.
		set astid to AppleScript's text item delimiters
		set AppleScript's text item delimiters to {" "}
		-- In case we receive something that is not text. If you want to handle images or audio, do it here...
		if the (count text items of theMessage) is less than 1 then return
		set theCommand to (the first text item of theMessage as string)
		try
			-- The argument is everything after the first word.
			set theArgument to (text items 2 thru -1 of theMessage as string)
		on error
			set theArgument to ""
		end try
		set AppleScript's text item delimiters to astid
		
		if theCommand is "pics" then
			set theResponse to getPicsFromSS(theArgument)
			
		else if theCommand is "cams" then
			-- Get camera names and return them
			tell application "SecuritySpy"
				set theCams to (get camera names)
				if (count theCams) = 1 then
					set theResponse to "There is 1 camera:" & return
				else
					set theResponse to "There are " & (count theCams) & " cameras:" & return
				end if
				set i to 0
				repeat with loopCam in theCams
					set i to i + 1
					set camMode to get mode camera name loopCam
					set theResponse to theResponse & (i & ": " & loopCam & " (" & camMode & ")" & return) as string
				end repeat
			end tell
			
			
		else if theCommand is "admins" and thisHandleIsAdmin is true then
			set theResponse to "Current admins:" & return
			repeat with loopAdmin in allAdmins
				set theResponse to theResponse & loopAdmin & return
			end repeat
			
		else if theCommand is "admin" and thisHandleIsAdmin is true then
			if theArgument is "" then
				set theResponse to "Usage: admin <handle>" & return & "Use the command \"subs\" to see which handles are currently subscribed. You can only make an admin from a handle that has previously subscribed to a camera. Use the command \"admins\" to see the current list of admin handles."
			else if theArgument is in allAdmins then
				set theResponse to "The handle you supplied is already an admin."
			else if theArgument is not in getAllSubs(false) then
				set theResponse to "The handle you supplied never subscribed: " & theArgument & return & "Use the command \"subs\" to see which handles are currently subscribed. You can only make an admin from a handle that has previously subscribed to a camera."
			else
				set theResponse to changeAdminStatus(theArgument)
			end if
			
		else if theCommand is "unadmin" and thisHandleIsAdmin is true then
			if theArgument is "" then
				set theResponse to "Usage: unadmin <handle>" & return & "Use the command \"admins\" to see which handles are currently admins."
			else if theArgument is theHandle then
				set theResponse to "You cannot remove your own admin privs."
			else if theArgument is not in allAdmins then
				set theResponse to "The handle you supplied is not an admin: " & theArgument
			else
				set theResponse to changeAdminStatus(theArgument)
			end if
			
		else if theCommand is "ignores" and thisHandleIsAdmin is true then
			set Ignores to getIgnores()
			if (count Ignores) is 0 then
				set theResponse to "There are no ignored handles."
			else if (count Ignores) is 1 then
				set theResponse to "There is 1 ignored handle: " & item 1 of Ignores as string
			else
				set theResponse to "Current ignored handles (" & (count Ignores) & "):" & return
				repeat with loopIgnore in Ignores
					set theResponse to theResponse & loopIgnore & return
				end repeat
			end if
			
		else if theCommand is "ignore" and thisHandleIsAdmin is true then
			if theArgument is "" then
				set theResponse to "Usage: ignore <handle>" & return & "Use the command \"subs\" to see which handles are currently subscribed."
			else if theArgument is theHandle then
				set theResponse to "You cannot ignore your own handle."
			else if theArgument is not in getAllSubs(false) then
				set theResponse to "The handle you supplied has never subscribed. You can only ignore a handle that has previously subscribed. Use the command \"subs\" to see a list of all subscribers."
			else if theArgument is in getIgnores() then
				set theResponse to "The handle you supplied is already ignored. Use the command \"ignores\" to see which handles are currently ignored."
			else
				set theResponse to changeIgnoreStatus(theArgument)
			end if
			
		else if theCommand is "unignore" and thisHandleIsAdmin is true then
			if theArgument is "" then
				set theResponse to "Usage: unignore <handle>" & return & "Use the command \"ignores\" to see which handles are currently ignored."
			else if theArgument is not in getIgnores() then
				set theResponse to "The handle you supplied is not being ignored. Use the command \"ignores\" to see which handles are currently ignored."
			else
				set theResponse to changeIgnoreStatus(theArgument)
			end if
			
		else if theCommand is "sub" then
			-- Subscribe to motion activated notices.
			tell application "SecuritySpy" to set cameraList to (get camera names)
			if theArgument is not "*" and theArgument is not in cameraList then
				set theResponse to "Usage: sub <camera|*>" & return & "Use of a * will subscribe you to all cameras. Use the command \"cams\" to see which cameras you can subscribe to."
			else
				set theResponse to SubscribeCam(theArgument, name of theBuddy, theHandle)
			end if
		else if theCommand is "unsub" then
			-- unubscribe from motion activated notices.
			if theArgument is "" then
				set theResponse to "Usage: unsub <camera|*>" & return & "Use of a * will unsubscribe you from all cameras."
			else
				set theResponse to unSubscribeCam(theArgument, theHandle)
			end if
			
		else if theCommand is "subs" then
			set Subscribers to getAllSubs(true)
			if (count Subscribers) is 1 then
				set theResponse to "You are the only subscriber, and you're an admin." & return
			else if thisHandleIsAdmin is true then
				set theResponse to "There are " & (count Subscribers) & " subscribers:" & return
			else
				set theResponse to "Here are your subscription details:" & return
			end if
			repeat with i from 1 to count Subscribers
				set loopSub to (item i of Subscribers)
				set loopHandle to item 1 of loopSub
				set loopContact to item 2 of loopSub
				set loopIgnored to item 3 of loopSub
				set loopAdmin to item 4 of loopSub
				set loopCams to item 5 of loopSub
				if loopHandle is theHandle or thisHandleIsAdmin is true then
					set theResponse to theResponse & i & ": " & loopHandle & " (" & loopContact & ") "
					if loopIgnored is true then
						set theResponse to theResponse & "IGNORED"
					else
						if loopHandle is theHandle then
							set theResponse to theResponse & "YOU, "
						else if loopAdmin is true then
							set theResponse to theResponse & "ADMIN, "
						end if
						if (count loopCams) is 0 then
							set theResponse to theResponse & "no cams"
						else if (count loopCams) is 1 then
							set theResponse to theResponse & "cam: " & camName of item 1 of loopCams
						else
							set theResponse to theResponse & "cams: "
							set i to 0
							repeat with loopCam in loopCams
								set i to i + 1
								set theResponse to theResponse & camName in loopCam
								if i is not (count loopCams) then set theResponse to theResponse & ", "
							end repeat
						end if
					end if
					set theResponse to theResponse & return
				end if
			end repeat
			
		else if theCommand is "stop" then
			-- temporarily stop all motion activated notices to this handle.
			if theArgument is "" then
				set theResponse to stopNotices(10, "*", theHandle)
			else
				set astid to AppleScript's text item delimiters
				set AppleScript's text item delimiters to {" "}
				try
					set theCamera to (text items 2 thru -1 of theArgument as string)
				on error
					set theCamera to "*"
				end try
				try
					set theCount to (the first text item of theArgument as string) as number
					set AppleScript's text item delimiters to astid
					set theResponse to stopNotices(theCount, theCamera, theHandle)
				on error
					set theResponse to "Usage: stop [minutes] [camera]"
				end try
			end if
			
		else if theCommand is "act" then
			-- Set camera to active state.
			tell application "SecuritySpy"
				if theArgument is "*" then
					active mode
					set theResponse to "All " & (count (get camera names)) & " cameras are now ACTIVE."
				else if theArgument is "" then
					set theResponse to "Usage: act <camera|*>" & return & "This command will set <camera> to an active state in SecuritySpy. This may enable notifications for this camera. Using a * will set all cameras to active."
				else if theArgument is in (get camera names) then
					active mode camera name theArgument
					set theResponse to "Camera " & theArgument & " is now ACTIVE."
				else
					set theReponse to "Usage: act <camera|*>" & return & "The camera name you provided does not exist. Use the command \"cams\" to see which cameras you can control. Sending \"act *\" will set all cameras to active."
				end if
			end tell
			
		else if theCommand is "pas" then
			-- Set camera to passive state.
			tell application "SecuritySpy"
				if theArgument is "*" then
					passive mode
					set theResponse to "All " & (count (get camera names)) & " cameras are now PASSIVE."
				else if theArgument is "" then
					set theResponse to "Usage: pas <camera|*>" & return & "This command will set <camera> to a passive state in SecuritySpy. This will disable notifications for this camera. Using a * will set all cameras to passive."
				else if theArgument is in (get camera names) then
					passive mode camera name theArgument
					set theResponse to "Camera " & theArgument & " is now PASSIVE."
				else
					set theResponse to "Usage: pas <camera|*>" & return & "The camera name you provided does not exist. Use the command \"cams\" to see which cameras you can control. Sending \"pas *\" will set all cameras to passive."
				end if
			end tell
		else if theCommand is "reset" then
			if theArgument is not "really" then
				set theResponse to "You must send reset with the word really after to really reset the system plist."
			else
				-- Delete the sandboxed file in case we're running out of the sandbox.
				do shell script "rm -f ~/Library/Containers/com.apple.iChat/Library/Preferences/com.cartcrafter.iMessageSpy.plist"
				do shell script "rm -f ~/Library/Preferences/com.cartcrafter.iMessageSpy.plist"
				-- Delete the old files too. It was renamed on Mar 10, 2017.
				do shell script "rm -f ~/Library/Containers/com.apple.iChat/Library/Preferences/com.cartcrafter.SSHelper.plist"
				do shell script "rm -f ~/Library/Preferences/com.cartcrafter.SSHelper.plist"
				set theResponse to "System reset. You should now subscribe to a camera to become an admin."
			end if
			
		else if theCommand is "help" then
			set theResponse to " - iMessageSpy Help - " & return
			set theResponse to theResponse & "Available User Commands:" & return
			set theResponse to theResponse & "cams - Displays all available cameras by name." & return
			set theResponse to theResponse & "pics [camera] - Sends pictures from all cameras, or from [camera]." & return
			set theResponse to theResponse & "sub <camera|*> - Enables motion notifications from <camera>" & return
			set theResponse to theResponse & "unsub <camera|*> - Stops motion notifications from <camera>" & return
			set theResponse to theResponse & "stop [minutes] [camera] - Stops all motion notifications for 10 minutes or [minutes] on all cameras or [camera]" & return
			if thisHandleIsAdmin is true then
				set theResponse to theResponse & return & "Available Admin Commands:" & return
				set theResponse to theResponse & "subs - Shows all subscribers' information." & return
				set theResponse to theResponse & "act <camera|*> - Sets <camera> to active." & return
				set theResponse to theResponse & "pas <camera|*> - Sets <camera> to passive." & return
				set theResponse to theResponse & "ignores - Lists all ignored handles." & return
				set theResponse to theResponse & "ignore <handle> - Ignores <handle>; stops notifications." & return
				set theResponse to theResponse & "unignore <handle> - Stop ignoring <handle>" & return
				set theResponse to theResponse & "admins - Lists all administrator handles." & return
				set theResponse to theResponse & "admin <handle> - Makes <handle> an admin." & return
				set theResponse to theResponse & "unadmin <handle> - Take away admin from <handle>" & return
				set theResponse to theResponse & "reset <really> - Delete the plist files to reset this system." & return
				-- This probably only works on a MacBooks.
			end if
			-- Load any available plugins and display their help info.
			tell application "Finder" to set myPath to container of (path to me) as text
			set pluginFiles to (list folder (myPath & "iMessageSpy_Plugins:") without invisibles)
			if (count of pluginFiles) is greater than 0 then
				set theResponse to theResponse & "Available Plugin Commands:" & return
				repeat with loopPlugin in pluginFiles
					set pluginPath to myPath & "iMessageSpy_Plugins:" & loopPlugin
					try
						set DynoPlugin to load script file (pluginPath)
						set theCmd to text 1 thru -6 of loopPlugin
						set theResponse to theResponse & DynoPlugin's HelpLine(theCmd, thisHandleIsAdmin) & return
					end try
				end repeat
			end if
		else if theCommand does not contain ":" then -- Best security we got, right here.
			-- Check for dynamic plugin. This allows you to extend the command set here.
			tell application "Finder" to set myPath to container of (path to me) as text
			set pluginPath to myPath & "iMessageSpy_Plugins:" & theCommand & ".scpt"
			if (exists file pluginPath of application "System Events") then
				if thisHandleIsAdmin then set theResponse to "Found plugin at " & pluginPath
				set pluginCmd to ""
				set pluginArgs to ""
				set astid to AppleScript's text item delimiters
				try
					set AppleScript's text item delimiters to {" "}
					if theArgument is not "" then
						set pluginCmd to (the first text item of theArgument as string)
					end if
					set pluginArgs to (text items 2 thru -1 of theArgument as string)
				end try
				set AppleScript's text item delimiters to astid
				try
					set DynoPlugin to load script file (pluginPath)
					set theResponse to DynoPlugin's MainRoutine(theCommand, theHandle, pluginCmd, pluginArgs, thisHandleIsAdmin)
				on error
					if thisHandleIsAdmin then set theResponse to "Error with plugin: " & pluginPath
				end try
			end if
		end if
		
		-- Send our response. One message at a time. This works with an array or text string.
		if class of theResponse is list then
			repeat with response in theResponse
				delay 0.2
				send response to theChat
				delay 0.2
			end repeat
		else
			send theResponse to theChat
		end if
		delay 3
		close windows
	end message received
	
	-- When first message is received, accept the invitation.
	on received text invitation theMessage from theBuddy for theChat
		accept theChat
		send "Welcome! Send \"help\" for help." to theChat
	end received text invitation
	-- Saw these declines in lazerwalker's hubot. Not sure if they're needed, but meh, why not.
	on received audio invitation theText from theBuddy for theChat
		decline theChat
	end received audio invitation
	on received video invitation theText from theBuddy for theChat
		decline theChat
	end received video invitation
	on received file transfer invitation theFileTransfer
		decline theFileTransfer
	end received file transfer invitation
	on buddy authorization requested theRequest
		accept theRequest
	end buddy authorization requested
	-- The following are unused but need to be defined to avoid an error.
	on message sent theMessage for theChat
	end message sent
	on chat room message received theMessage from theBuddy for theChat
	end chat room message received
	on active chat message received theMessage
	end active chat message received
	on addressed chat room message received theMessage from theBuddy for theChat
	end addressed chat room message received
	on addressed message received theMessage from theBuddy for theChat
	end addressed message received
	on av chat started
	end av chat started
	on av chat ended
	end av chat ended
	on login finished for theService
	end login finished
	on logout finished for theService
	end logout finished
	on buddy became available theBuddy
	end buddy became available
	on buddy became unavailable theBuddy
	end buddy became unavailable
	on completed file transfer
	end completed file transfer
end using terms from
