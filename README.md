# iMessageSpy
SecuritySpy - Messages.app and iMessage Integration

### Description
I've created two scripts that allow you to interact with and control part of SecuritySpy using iMessages and the Messages.app. I've tested this on 10.11 and 10.12, but it may work on older versions of Mac OS X. 

### Features
What can you do with this? You can tell SecuritySpy to send you pictures from your cameras when they detect motion. You can tell SecuritySpy to send you pictures of any camera immediately (regardless of active/passive or motion detection settings). These are the main two features of the package.

A plugin mechanism also exists in the script. Two (or more) demo plugins are available.

- This set of scripts also provides commands to control access. (see screen shots)
- You should use this with a dedicated SecuritySpy machine ("server"). 
- You must create and use an Apple ID account specifically for iMessages on your SecuritySpy server.
- No one knows the account, so it's fairly secure just considering that.
- Do not give people the account nor tell them the commands and your privacy will be pretty safe.
- You can ignore users or change the account (Apple ID) at any time.

#### Screen shots

- TODO: new screen shots, these are old and suck.
1. http://cl.ly/image/123A4136352s
2. http://cl.ly/image/100p3s1z1J0N

### Installation
Installation is simple, but requires a few steps. Make sure your server is signed into an iMessage account with Messages. SecuritySpy should be active with at least 1 camera.

There is an install script! This will hopefully make some of this less painful. Open a Terminal window and drag `install.sh` onto it. Then press enter.
This script will do the following:
* Copy the file `iMessageSpy.applescript` to `~/Library/Application Scripts/com.apple.iChat/`
* Copy the file `SS_SendiMessages.scpt` to `~/Documents/SecuritySpy/Scripts/`
    * The ~ means your home folder, usually something like /Users/yourname
* Copy the iMessageSpy_Plugins folder and plugins to ~/Library/Application Scripts/com.apple.iChat/iMessage_Plugins

*The script will not do the following, and you must do these things manually:*
* Quit and re-open Messages.app
    * Go to Preferences > General
    * Select `iMessageSpy.applescript` as the AppleScript handler.
* Quit and re-open SecuritySpy
    * Go to Settings > Camera Settings > Actions 
    * Put a check next to "Run Script" then select `SS_SendiMessages.scpt`
    * DO THIS FOR EACH CAMERA.

That's it, it's all loaded. Now, from another computer or your phone send an iMessage to this system with the word `cams` - you should receive a list of your cameras. Send `sub *` to subscribe to all of them. Send `help` for help.

### Plugins

TODO: more information about how to write plugins.

### Bugs

Sometimes the script runs too slowly and "crashes." This will require you to force quit Messages.app and re-open it. Adding delays helps, but it's still not 100%.
There is a workaround for this problem. See the script @ https://github.com/davidnewhall/IndigoAppleScripts/blob/master/Restart_Messages.applescript
This script looks for a window in Messages that has a button named "Wait" or a button named "Ignore Error" - if it sees either of these it will kill and restart Messages.app.
If you have a few cameras or subscribers, you will unfortunately find that running this extra script is non-optional.

Some users have reported that sending "pics" does not send them all their cameras. Most people report only getting 1 picture. I have reproduced this problem on two systems;
both of these systems are macOS 10.12. This problem is not repeatable on Mac OS X 10.11. I also ran into a number of other problems with macOS 10.12 and I have reverted my
own system to 10.11. I know many of you are on 10.12 so I will continue to support it. I have made changes to make this better on 10.12, but it is still not 100% resolved.
I generally get 5 out of 6 pictures. If you have fewer cameras your odds are better. This is 100% a bug in Messages.app because as I reproduce the problem the pictures on 
the servers (those that were sent) are not all the same as those on the client (those that were received). Apple is pretty bad about supporting Messages.app with AppleScript
so this may be a long-standing problem.

Feel free to send along PRs. If you have something to ask/suggest, I usually check this forum thread:
http://www.bensoftware.com/forum/discussion/949/securityspy-messages-app-and-imessage-integration
