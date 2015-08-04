#!/bin/bash
launchctl unload /Library/LaunchDaemons/com.adobe.fpsaud.plist
rm -rf "/Applications/Utilities/Adobe Flash Player Install Manager.app"
rm -rf "/Library/Application Support/Macromedia"
rm -rf "/Library/Application Support/Adobe/Flash Player Install Manager"
rm -rf "/Library/Internet Plug-Ins/Flash Player.plugin"
rm -rf /Library/LaunchDaemons/com.adobe.fpsaud.plist
exit 0