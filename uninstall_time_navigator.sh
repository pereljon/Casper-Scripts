#!/bin/sh
killall tina_daemon
rm -rf /Applications/Atempo
rm -rf /private/etc/Atempo
rm -rf /Library/Receipts/Time_Navigator_Binaries.pkg
rm -rf /Library/Receipts/Time_Navigator_Launcher.pkg
rm -rf /Library/Widgets/BackupActivity.wdgt
rm -rf /Library/StartupItems/tina.tina
killall Dock
exit 0