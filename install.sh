#!/bin/sh
# This simple shell script will install the two iMessageSpy AppleScripts and any plugins in the package.
# It is perfectly safe to run multiple times. If the repo changes, you should certainly run it again.

echo "==> Beginning installation of iMessageSpy."

# Location of the script in the file system. Our source files should be here too.
MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MY_HOME=$(echo ~)

echo "<=> Creating folder: ~/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins"
mkdir -p "$MY_HOME/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins"

echo "<=> Compiling 'SS_SendiMessages.scpt' -> ~/Documents/SecuritySpy/Scripts/"
/usr/bin/osacompile -o "$MY_HOME/Documents/SecuritySpy/Scripts/SS_SendiMessages.scpt" "$MY_DIR/SS_SendiMessages.scpt"

echo "<=> Copying 'iMessageSpy.applescript' -> ~/Library/Application Scripts/com.apple.iChat/"
cp "$MY_DIR/iMessageSpy.applescript" "$MY_HOME/Library/Application Scripts/com.apple.iChat/iMessageSpy.applescript"

# Compile all included plugins.
cd "$MY_DIR/iMessageSpy_Plugins/"
# This IFS trick preserves files with spaces, even though scripts should not have any spaces - they wont work that way.
IFS=$'\n'
for i in *.scpt; do 
    echo "<=> Compiling '$i' -> ~/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins/"
    /usr/bin/osacompile -o "$MY_HOME/Library/Application Scripts/com.apple.iChat/iMessageSpy_Plugins/$i" "$i"
done
echo "<== All files should now be in place."
echo "==> Make sure to configure the AppleScript Handler in Messages.app to use iMessageSpy.applescript."
echo "==> And configure the 'Run Script' Action on each of your cameras to run SS_SendiMessages.scpt."
