#!/bin/bash

# Param 4: Name of the new signature in Mail.app
signatureName="$4"

# Param 5: Path to the new signature template file
signatureTemplate="$5"
# The following tokens are replaced in the signature template file
# USERNAME - replaced with the CN of the user
# TITLE - replaced with the title of the user
# PHONE - replaced with the phone number of the user

# Param 6: Manual UUID for signature (optional: random UUID is generated otherwise)
theUUID="$6"

# Param 7: Mail server which will be used to find the account to attach the new signature to
serverMail="$7"

# Param 8: Path of the icon shown on the message dialog
dialogIconPath="$8"

# Params 9 & 10: JSS API User and password: used to lookup the username, title and phone info
JSS_API_USER="$9"
JSS_API_PASS="$10"

# Constants
dialogTitle="Install Mail Signature"
messageQuitMail="Please quit Mail.app to install the new email signature. Mail.app will launch once the install has completed."
messageDone="The new email signature has been installed. Please verify that it has been properly customized for you."
CURL_OPTIONS="--silent --connect-timeout 30"

# Aliases
jamf_helper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
PlistBuddy="/usr/libexec/PlistBuddy -c"

# Check parameters
if [[ -z "$signatureName" ]]; then
	echo "error: empty signature name"
	exit 1	
fi
if [[ -z "$signatureTemplate" ]]; then
	echo "error: empty signature template"
	exit 1	
fi
if [[ ! -f "$signatureTemplate" ]]; then
	echo "error: template not found at: $signatureTemplate"
	exit 1
fi
if [[ -z "$serverMail" ]]; then
	echo "error: empty mail server address"
	exit 1	
fi
if [[ -z "$dialogIconPath" ]]; then
	echo "error: empty dialog icon path"
	exit 1	
fi
if [[ ! -f "$dialogIconPath" ]]; then
	echo "error: dialog icon not found at: $dialogIconPath"
	exit 1
fi
if [[ -z "$theUUID" ]]; then
	# Generate random UUID for signature if one wasn't provided as a parameter
	theUUID="$(uuidgen)"
fi

# Identify location of jamf binary.
jamf_binary=$(/usr/bin/which jamf)
if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/sbin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
fi

# Check JSS connection is up
JSS_CONNECTION="$($jamf_binary checkJSSConnection)"
if [ ! ${JSS_CONNECTION} ]; then
    echo "No connection to JSS"
    exit 1
fi

# Get base URL to JSS from prefs
JSS_BASEURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
if [ -z "${JSS_BASEURL}" ]; then
    echo "Couldn't find JSS base URL"
    exit 1
fi

# Get system hardware uuid
MY_UUID="$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')"
if [ -z "${MY_UUID}" ]; then
    echo "Couldn't find system UUID"
    exit 1
fi

# Perform web service call to JSS to get user information
JSS_APIURL="${JSS_BASEURL}JSSResource/"
RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${JSS_API_USER}":"${JSS_API_PASS}" "${JSS_APIURL}computers/udid/${MY_UUID}/subset/location")
if [ -z "${RESULT_XML}" ]; then
    echo "Couldn't get XML from JSS webservice"
    exit 1
fi

# Filter out the name, title and phone number
theName="$(echo "${RESULT_XML}" | xpath "string(/computer/location/real_name)" 2> /dev/null)"
thePhone="$(echo "${RESULT_XML}" | xpath "string(/computer/location/phone)" 2> /dev/null)"
theTitle="$(echo "${RESULT_XML}" | xpath "string(/computer/location/position)" 2> /dev/null)"
# Escape any amperstand (&) in the title because of sed
theTitle="$(echo "${theTitle}" | sed 's/&/\\&/g')"

# Get logged in user name
loggedIn=$(who|grep console|grep -v _mbsetupuser)
if [[ -z "$loggedIn" ]]; then
	echo "error: user not logged in"
	exit 1	
fi
theUID=$(echo "$loggedIn"|awk '{print $1}')

# Get logged in user's home
theHome=$(/usr/bin/su "$theUID" -c "echo ~/")

# Get base folder for mail depending on OS version
theOSVersion="$(/usr/bin/sw_vers -productVersion)"
theOSVerionMajor="$(echo ${theOSVersion}|cut -c 1-2)"
theOSVerionMinor="$(echo ${theOSVersion}|cut -c 4-5)"
if [[ $theOSVerionMajor != "10" ]]; then
	# Error: expecting os to start with "10"
	echo "error: unknown os version ${theOSVersion}"
	exit 1
elif [[ $theOSVerionMinor -ge "11" ]]; then
	# OS 10.11 or greater
	echo "OS is 10.11 or greater"
	baseFolder="${theHome}Library/Mail/V3"
	iCloudFolderSignatures="${theHome}Library/Mobile Documents/com~apple~mail/Data/V3/MailData/Signatures"
else
	# OS 10.10 or less
	baseFolder="${theHome}Library/Mail/V2"
	iCloudFolderSignatures="${theHome}Library/Mobile Documents/com~apple~mail/Data/MailData/Signatures"
fi
echo "OS version: ${theOSVersion}"
echo "Base folder: ${baseFolder}"

# Get and check signatures folder
folderSignatures="${baseFolder}/MailData/Signatures"
if [[ ! -d $folderSignatures ]]; then
	echo "error: signature folder not found"
	exit 1
fi

# Check AllSignatures.plist file
fileAllSignature="${folderSignatures}/AllSignatures.plist"
if [[ ! -f $fileAllSignature ]]; then
	echo "error: AllSignatures.plist file not found"
	exit 1
fi

# Check and get the accountUUID from AccountsMap.plist file
fileAccountsMap="${folderSignatures}/AccountsMap.plist"
if [[ ! -f $fileAccountsMap ]]; then
	echo "error: AccountsMap.plist file not found"
	exit 1
fi

theAccountsMap=$(defaults read "$fileAccountsMap")
theAccountCount=$(echo "$theAccountsMap"|grep -c "imap.*\..*${serverMail}")
if [ "$theAccountCount" -eq "1" ]; then
	# Only one possible account
	theAccountUUID=$(echo "$theAccountsMap" | grep -B 1 -E "imap.*${serverMail}" | grep -v "${serverMail}" | awk '{print $1}' | sed s/\"//g )
else
	echo "Error #${theAccountCount}: Can't find imap account for ${serverMail} in AccountsMap.plist"
	exit 1
fi

# Check to see if Mail.app is running
mailRunning=$(pgrep -f "Mail.app")
if [[ -n "$mailRunning" ]]; then
	# Mail.app is running, ask user to quit
	"$jamf_helper" -windowType utility -icon "$dialogIconPath" -title "$dialogTitle" -description "$messageQuitMail" &
	while [ -n "$(pgrep -x "Mail")" ]; do
		sleep 1
	done
	pkill jamfHelper
fi

# Remove SyncedFilesInfo.plist
fileMailSync="${baseFolder}/MailData/SyncedFilesInfo.plist"
if [[ -f $fileMailSync ]]; then
	rm "$fileMailSync"
fi

# Replace tokens in template file and create new signature file
fileMailSignature="${folderSignatures}/${theUUID}.mailsignature"
cat "$signatureTemplate" | sed "s^PHONE^$thePhone^g" | sed "s^USERNAME^$theName^g" |  sed "s^TITLE^$theTitle^g" > "$fileMailSignature"
chown "$theUID" "$fileMailSignature"

# Remove pre-existing iCloud signature
iCloudFileMailSignature="${iCloudFolderSignatures}/ubiquitous_${theUUID}.mailsignature"
if [[ -f ${iCloudFileMailSignature} ]]; then
	rm "${iCloudFileMailSignature}"
fi

# Check if the signature is already installed in the AllSignatures.plist 
installedAllSignatures=$(grep "$theUUID" "$fileAllSignature")
if [[ -z "$installedAllSignatures" ]]; then 
	# Add new signature file to AllSignatures.plist
	echo "Add signature to AllSignatures.plist"
	sed -i '' "/<\/array>/ i\ 
	\	<dict>\\
	\		<key>SignatureIsRich</key>\\
	\		<true/>\\
	\		<key>SignatureName</key>\\
	\		<string>$signatureName</string>\\
	\		<key>SignatureUniqueId</key>\\
	\		<string>$theUUID</string>\\
	\	</dict>\\
	" "$fileAllSignature"
else
	echo "Signature exists in AllSignatures.plist"
fi

# Check if the signature is already installed in the AccountsMap.plist
installedAccountsMap=$($PlistBuddy "Print :${theAccountUUID}:Signatures:" "$fileAccountsMap"|grep "$theUUID")
if [[ -z "$installedAccountsMap" ]]; then 
	# Add the new signature UUID to AccountsMap.plist
	echo "Add signature to AccountsMap.plist"
	$PlistBuddy "Add :${theAccountUUID}:Signatures: string $theUUID" "$fileAccountsMap"
else
	echo "Signature exists in AccountsMap.plist"
fi

# While loop to set com.apple.mail.plist because sometimes it doesn't work because of cfprefsd caching on Mavericks
while true; do
# Check if the account has a default signature in com.apple.mail.plist preference
	installedDefaultSignature=$(defaults read "${theHome}/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist" SignaturesSelected|grep "$theAccountUUID"|grep "$theUUID")
	if [[ -z "$installedDefaultSignature" ]]; then
		# Signature with theUUID is NOT installed for the theAccountUUID
		installedDefaultSignature=$(defaults read "${theHome}/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist" SignaturesSelected|grep "$theAccountUUID")
		if [[ -z "$installedDefaultSignature" ]]; then
			# There are no default signatures for theAccountUUID
			# Add signature theUUID for the theAccountUUID
			echo "Add default signature to com.apple.mail.plist"
			$PlistBuddy "Add :SignaturesSelected:$theAccountUUID string $theUUID" "${theHome}/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist"
		else
			# There is a default signature for theAccountUUID
			# Set signature theUUID for the theAccountUUID
			echo "Set defaultsignature to com.apple.mail.plist"
			$PlistBuddy "Set :SignaturesSelected:$theAccountUUID $theUUID" "${theHome}/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist"
		fi
	else
		echo "Default signature exists in com.apple.mail.plist"
		break	
	fi
done

# Kill preferences caching daemon
pkill -U "${theUID}" cfprefsd

# Display "done" dialog message
"$jamf_helper" -windowType utility -icon "$dialogIconPath" -title "$dialogTitle" -description "$messageDone" -button1 "OK"

# Open Mail.app
/usr/bin/su -l "$theUID" -c "open /Applications/Mail.app"

exit 0