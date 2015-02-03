#!/bin/bash
# Aliases for commands
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# Constants
CURL_OPTIONS="--silent --connect-timeout 30"
jhWindowType="fs"
jhTitle="Post-boot imaging:"
# API User and passwors
MY_API_USER="JSS_API_USER"
MY_API_PASS="JSS_API_PASSWORD"

# Stop and remove enrollment
echo "Removing from JSS"
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing enrollment." &
/bin/rm -rf '/Library/Application Support/JAMF/FirstRun/Enroll/'
/bin/rm /Library/LaunchDaemons/com.jamfsoftware.firstrun.enroll.plist
/bin/launchctl remove com.jamfsoftware.firstrun.enroll

# Remove from JSS Server
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS." &
MY_JSS_BASEURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
if /usr/sbin/jamf checkJSSConnection; then
    if [ -n "${MY_JSS_BASEURL}" ]; then
        MY_JSS_APIURL="${MY_JSS_BASEURL}JSSResource/"
        MY_UUID=$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')
        if [ -n "${MY_UUID}" ]; then
            RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${MY_API_USER}":"${MY_API_PASS}" "${MY_JSS_APIURL}computers/udid/${MY_UUID}/subset/general")
            if [ -n "${RESULT_XML}" ]; then
                RESULT_ID=$(echo "${RESULT_XML}" | xpath "string(/computer/general/id)" 2> /dev/null)
                if [ -n "${RESULT_ID}" ]; then
                    #delete computer from JSS server
                    /usr/bin/curl ${CURL_OPTIONS} --request DELETE --user "${MY_API_USER}":"${MY_API_PASS}" "${MY_JSS_APIURL}computers/id/${RESULT_ID}"
                else
                    killall jamfHelper
                    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting ID" &
                    /bin/sleep 60
                fi
            else
                killall jamfHelper
                "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting XML" &
                /bin/sleep 60
            fi
        else
            killall jamfHelper
            "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting UUID" &
            /bin/sleep 60
        fi
    else
        killall jamfHelper
        "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting URL" &
        /bin/sleep 60
    fi
else
    killall jamfHelper
    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error connecting to JSS" &
    /bin/sleep 60
fi

# Remove profiles
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing profiles." &
/usr/bin/profiles -Df

# Delete management user
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Deleting management user." &
if [ -n "${RESULT_XML}" ]; then
    MANAGEMENT_USERNAME=$(echo "${RESULT_XML}" | xpath "string(/computer/general/remote_management/management_username)" 2> /dev/null)
    if [ -n "${MANAGEMENT_USERNAME}" ]; then
        #delete computer from JSS server
        /usr/sbin/dseditgroup -o edit -d "${MANAGEMENT_USERNAME}" -t user admin
        /usr/sbin/dseditgroup -o edit -d "${MANAGEMENT_USERNAME}" -t user appserveradm
        /usr/sbin/dseditgroup -o edit -d "${MANAGEMENT_USERNAME}" -t user appserverusr
        /usr/bin/dscl . -delete "/Users/${MANAGEMENT_USERNAME}"
    else
        killall jamfHelper
        "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Deleting management user: Missing XML" &
        /bin/sleep 60
    fi
fi

# Clear out logs
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Clearing out log, cache, and vm system files." &
rm -rf /Library/Keychains/*
rm -rf /Library/Preferences/SystemConfiguration/*
rm -rf /private/db/.configureLocalKDC
rm -rf /private/db/systemstats/*
rm -rf /private/db/BootCaches
rm -rf /private/db/spindump/*
rm -rf /private/var/log/*
rm -rf /private/var/folders/*
rm -rf /private/var/vm/*

# Remove framework
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing framework and rebooting." &
/usr/sbin/jamf removeFramework
rm -rf "/Library/Application Support/JAMF"
rm /Library/Preferences/com.jamfsoftware.jamf.plist

# Reboot
killall jamfHelper
/sbin/reboot &

# Wait for shutdown
#killall jamfHelper
#"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Waiting for shutdown..." &

exit 0