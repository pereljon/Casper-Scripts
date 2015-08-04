#!/bin/bash
echo "Remove from JSS"

# Username and password
MY_API_USER="API-USERNAME"
MY_API_PASS="API-PASSWORD"

# Aliases for commands
# jamfHelper: [-windowType [hud|utility|fs]] [-icon path] [-title "title"] [-description "description"]
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# Constants
jhWindowType="fs"
jhTitle="Post-boot imaging:"
CURL_OPTIONS="--silent --connect-timeout 30"

# Stop and remove enrollment
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing enrollment." &
/bin/rm -rf '/Library/Application Support/JAMF/FirstRun/Enroll/'
/bin/rm /Library/LaunchDaemons/com.jamfsoftware.firstrun.enroll.plist
/bin/launchctl remove com.jamfsoftware.firstrun.enroll

# Remove from JSS Server
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS." &
/bin/sleep 5
MY_JSS_BASEURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
if /usr/sbin/jamf checkJSSConnection; then
    killall jamfHelper
    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Connected" &
    /bin/sleep 5
   if [ -n "${MY_JSS_BASEURL}" ]; then
        killall jamfHelper
        "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Got URL: $MY_JSS_BASEURL" &
        /bin/sleep 5
    	MY_JSS_APIURL="${MY_JSS_BASEURL}JSSResource/"
    	MY_UUID=$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')
    	if [ -n "${MY_UUID}" ]; then
            killall jamfHelper
            "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Got UUID: $MY_UUID" &
            /bin/sleep 5
    		RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${MY_API_USER}":"${MY_API_PASS}" "${MY_JSS_APIURL}computers/udid/${MY_UUID}/subset/general")
    		if [ -n "${RESULT_XML}" ]; then
                killall jamfHelper
                "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Got XML" &
                /bin/sleep 5
    			RESULT_ID=$(echo "${RESULT_XML}" | xpath "string(/computer/general/id)" 2> /dev/null)
    			if [ -n "${RESULT_ID}" ]; then
    				#delete computer from JSS server
                    killall jamfHelper
                    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Got ID: $RESULT_ID" &
                    /bin/sleep 5
    				/usr/bin/curl ${CURL_OPTIONS} --request DELETE --user "${MY_API_USER}":"${MY_API_PASS}" "${MY_JSS_APIURL}computers/id/${RESULT_ID}"
                else
                    killall jamfHelper
                    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Getting ID" &
                    /bin/sleep 5
    			fi
    			RESULT_USERNAME=$(echo "${RESULT_XML}" | xpath "string(/computer/general/remote_management/management_username)" 2> /dev/null)
    		else
                killall jamfHelper
                "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting XML" &
                /bin/sleep 5
    		fi
    	else
            killall jamfHelper
            "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting UUID" &
            /bin/sleep 5
    	fi
    else
        killall jamfHelper
        "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error getting URL" &
        /bin/sleep 5
    fi
else
    killall jamfHelper
    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Removing from JSS: Error connecting to JSS" &
    /bin/sleep 5
fi

# Remove profiles
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Remove profiles." &
/usr/bin/profiles -Df

# Delete jssuser
if [ -n "${RESULT_USERNAME}" ]; then
	#delete computer from JSS server
    killall jamfHelper
    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Delete user: ${RESULT_USERNAME}." &
    /bin/sleep 5
    /usr/sbin/dseditgroup -o edit -d ${RESULT_USERNAME} -t user admin
    /usr/sbin/dseditgroup -o edit -d ${RESULT_USERNAME} -t user appserveradm
    /usr/sbin/dseditgroup -o edit -d ${RESULT_USERNAME} -t user appserverusr
    /usr/bin/dscl . -delete "/Users/${RESULT_USERNAME}"
else
    killall jamfHelper
    "$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Delete user: Not found " &
    /bin/sleep 5
fi
    			
# Clear out logs
killall jamfHelper
"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Clear out log, cache, and vm system files." &
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

# Schedule shutdown
killall jamfHelper
/sbin/reboot &

# Wait for shutdown
#killall jamfHelper
#"$JAMFHELPER" -windowType "$jhWindowType" -title "$jhTitle" -description "Waiting for shutdown..." &

exit 0