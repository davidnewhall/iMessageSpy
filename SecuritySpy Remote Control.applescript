using terms from application "Messages"
	on getPicsFromSS(getCamera)
		tell application "SecuritySpy" to set CameraNames to (get camera names)
		if getCamera is "" then
			set theResponse to {}
			repeat with CameraLoop in CameraNames
				set theFile to "/tmp/securityspy_imessage_file_" & CameraLoop & ".jpg"
				tell application "SecuritySpy" to capture image as theFile camera name CameraLoop with overwrite
				set the end of theResponse to CameraLoop & " Camera:"
				delay 0.1
				set the end of theResponse to POSIX file theFile
			end repeat
		else if getCamera is not in CameraNames then
			set theResponse to {"Camera not found: " & getCamera}
			set the end of theResponse to "Use \"cams\" to see the camera names. Send \"pics\" to see a picture from each camera."
		else
			set theFile to "/tmp/securityspy_imessage_file_" & getCamera & ".jpg"
			tell application "SecuritySpy" to capture image as theFile camera name getCamera with overwrite
			delay 0.1
			set theResponse to {POSIX file theFile}
		end if
		return theResponse
	end getPicsFromSS
	
	-- brightness should be between 0 and 1.
	on DisplayBrightness(brightness)
		tell application "System Preferences"
			activate
			reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
			tell application "System Events"
				delay 0.5
				set value of slider 1 of group 1 of tab group 1 of window 1 of process "System Preferences" to brightness
			end tell
			quit
		end tell
		return {"Displayed brightness set to " & (round (brightness * 100)) & "%"}
	end DisplayBrightness
	
	on SubscribeCam(subCam, subName, subHandle)
		
		global plistFilePath
		if not (exists file plistFilePath of application "Finder") then
			-- This next line is a stupid hack required on Yosemite.
			do shell script "defaults write " & (POSIX path of plistFilePath) & " Subscribers -boolean TRUE"
			tell application "System Events"
				set plistdir to make new property list item with properties {kind:record}
				set plistfile to make new property list file with properties {contents:plistdir, name:plistFilePath}
				make new property list item at end of property list items of contents of plistfile with properties {kind:list, name:"Subscribers"}
			end tell
		end if
		
		-- this code is not done.
		tell application "System Events"
			tell property list file plistFilePath
				tell contents
					set previousValue to value of property list item "Subscribers"
					if exists property list item "handle" of every property list item of property list item "Subscribers" then
						set allSubs to value of every property list item of property list item "Subscribers" as list
						set subExists to false
						set newSubList to {}
						repeat with i from 1 to count allSubs
							set loopSub to (item i of allSubs)
							if handle of loopSub is subHandle then
								set subExists to true
								if subCam is in cameras of loopSub then
									return "You are already subscribed to this camera."
									-- we don't do anything..
									set newSubList's end to allSubs's item i
								else
									-- Add new camera to previous subscriber.
									set newCams to (cameras of loopSub & subCam)
									set newSubList's end to {handle:subHandle, admin:admin of loopSub, ignored:ignored of loopSub, contact:subName, stopat:current date, cameras:newCams}
									return "You are now subscribed to " & (count newCams) & " cameras."
								end if
							else
								-- just keep the record, not the user we're after.
								set newSubList's end to allSubs's item i
							end if
						end repeat
						if subExists is false then
							-- new subscriber, but not the first, so no admin flag.
							set newSubList's end to {handle:subHandle, admin:false, ignored:false, contact:subName, stopat:current date, cameras:{subCam}}
							return "You have been successfully subscribed to your first camera."
						end if
						set value of property list item "Subscribers" to newSubList
					else
						-- First user, create with admin flag.
						set value of property list item "Subscribers" to (previousValue & {{handle:subHandle, admin:true, ignored:false, contact:subName, stopat:(current date) - (3660 * days), cameras:{subCam}}})
						return "You have subscribed to your first camera, and since you are the first subscriber you have been given admin powers."
					end if
				end tell
			end tell
		end tell
	end SubscribeCam
	
	on message received theMessage from theBuddy for theChat
		--Initialize an empty response.
		set theResponse to {}
		-- The command is the first word.
		set theCommand to (the first word of text of theMessage as string)
		if the (count words of theMessage) is greater than 1 then
			-- The argument is everything after the first word.
			set theArgument to (words 2 thru -1 of theMessage as string)
		else
			set theArgument to ""
		end if
		
		if theCommand is "pics" then
			set theResponse to getPicsFromSS(theArgument)
			
		else if theCommand is "cams" then
			-- Simply get camera names and return them
			tell application "SecuritySpy" to set theResponse to (get camera names)
			
		else if theCommand is "screen" then
			-- Turn the display on or off (by adjusting the birhgtness.
			if (theArgument is not "on" and theArgument is not "off") then
				set theResponse to {"Usage: screen [on|off]"}
			else if theArgument is "on" then
				set theResponse to DisplayBrightness(0.8)
			else
				set theResponse to DisplayBrightness(0)
			end if
			
		else if theCommand is "sub" then
			-- Subscribe to motion activated notices.
			tell application "SecuritySpy" to set cameraList to (get camera names)
			if theArgument is "" and last character of theMessage is "*" then
				set theResponse to {"You are now subscribed to all " & (count cameraList) & " camera(s)."}
			else if theArgument is not in cameraList then
				set theResponse to {"Usage: sub <camera|*>"}
			else
				set theResponse to SubscribeCam(theArgument, name of theBuddy, handle of theBuddy)
			end if
		end if
		
		-- Send our response. One message at a time.
		repeat with Response in theResponse
			send Response to theChat
		end repeat
		close windows
	end message received
	
	-- When first message is received, accept the invitation.
	on received text invitation theMessage from theBuddy for theChat
		accept theChat
		send "Send \"pics\" to see a live picture from each camera." to theChat
		send "Send \"cams\" to see the camera names." to theChat
	end received text invitation
	
	# The following are unused but need to be defined to avoid an error
	on received audio invitation theText from theBuddy for theChat
	end received audio invitation
	on received video invitation theText from theBuddy for theChat
	end received video invitation
	on received remote screen sharing invitation from theBuddy for theChat
	end received remote screen sharing invitation
	on received local screen sharing invitation from theBuddy for theChat
	end received local screen sharing invitation
	on received file transfer invitation theFileTransfer
	end received file transfer invitation
	on buddy authorization requested theRequest
	end buddy authorization requested
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
