#!/bin/bash
launchctl unload /Library/LaunchDaemons/com.adobe* 2> /dev/null
launchctl unload /Library/LaunchAgents/com.adobe* 2> /dev/null
/usr/bin/pkill -if adobe
rm -rf  "/Applications/Adobe "*
rm -rf "/Applications/Utilities/Adobe Application Manager" "/Applications/Utilities/Adobe Creative Cloud" "/Applications/Utilities/Adobe Installers" "/Applications/Utilities/Adobe Utilities"*
rm -rf "/Library/Application Support/regid.1986-12.com.adobe" "/Library/Application Support/Adobe" "/Library/LaunchDaemons/com.adobe."* "/Library/LaunchAgents/com.adobe."*
rm -rf /Users/Shared/Adobe
rm -rf /Library/Logs/Adobe
rm -rf /Library/Preferences/com.adobe.*
rm -rf /private/var/db/receipts/com.adobe* /private/var/db/receipts/adobecs*
exit 0