# iMessageSpy
SecuritySpy - Messages.app and iMessage Integration

### Description
I've created two scripts that allow you to interact with and control part of SecuritySpy using iMessages and the Messages.app. I've tested this on 10.9 and 10.10, but it may work on older versions of Mac OS X. 

### Features
What can you do with this? You can tell SecuritySpy to send you pictures from your cameras when they detect motion. You can tell SecuritySpy to send you pictures of any camera immediately (regardless of active/passive or motion detection settings). These are the main two features of the package. It also provides some other commands so you can control access. I recommend you use this with a dedicated SecuritySpy machine ("server"). I made a new Apple ID account specifically for iMessages on this server, and setup Messages.app with this account. No one knows the account, so it's fairly secure just considering that. Do not give people the account nor tell them the commands and your privacy will be pretty safe.

### Installation
Installation is simple, but requires a few steps. First, make sure you are signed into an iMessage account with Messages and SecuritySpy is running with at least 1 camera.

* Copy the file "SecuritySpy Remote Control.applescript" to ~/Library/Application Scripts/com.apple.iChat/ 
* Copy the file "SS_SendiMessages.scpt" to ~/Documents/SecuritySpy/Scripts/
    * The ~ means your home folder, usually something like /Users/yourname
* Open Messages.app
    * Go to Preferences > General
    * Select "SecuritySpy Remote Control.applescript" as the AppleScript handler.
* Open SecuritySpy
    * Go to Settings > Camera Settings > Actions 
    * Put a check next to "Run Script" then select "SS_SendiMessages.scpt" 
    * DO THIS FOR EACH CAMERA.

That's it, it's all loaded. Now, from another computer or your phone send an iMessage to this system with the word "cams" - you should receive a list of your cameras. Send "sub *" to subscribe to all of them. Send "help" for help.

### Bugs
Things I've noticied and not yet had time to fix...

* sub * doesn't always work, especially if it's the first time you are subscribing. I recommend using 'sub SomeCamName' before doing sub *, that seems more reliable.
* If you send something to the script that is not text, it will crash. This includes pictures and audio. 
* Sometimes the script runs too slowly and "crashes." This will require you to force quit Messages.app and re-open it. Adding delays helps, but it's still not 100%.
* If you send "pics" and one of your cameras is disconnected/offline, it may crash trying to get a picture from that camera.
* People have reported issues when the script tries to create the initial plist file. Please file bugs on that so I can get more information.
* Capitalization is screwed up. I need to add a function to normalize/fix user input.
* Not really a bug, but things seem to work better if you add yourself and any other users to Contacts.app.

Feel free to send along PRs...
