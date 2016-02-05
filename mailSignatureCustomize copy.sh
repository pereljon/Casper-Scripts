#!/bin/bash

# Constants
dialogTitle="Install Mail Signature"
messageQuitMail="Please quit Mail.app to install the new email signature. Mail.app will launch once the install has completed."
messageDone="The new email signature has been installed. Please verify that it has been properly customized for you."
dialogIconPath="/Library/Application Support/JAMF/private/mylogo.png"

# Signature template
signatureName="My Custom Signature"
signatureTemplate="/Library/Application Support/JAMF/private/my.mailsignature"
# The following tokens are replaced in the signatureTemplate file
# USERNAME - replaced with the CN of the user
# TITLE - replaced with the title of the user
# PHONE - replaced with the phone number of the user

# Server setup
serverMail="MAIL.SERVER.COM"

### SET AUTHENTICATION BELOW ###
# JSS API user and password
JSS_API_USER="JSS_USER"
JSS_API_PASS="JSS_PASSWORD"
CURL_OPTIONS="--silent --connect-timeout 30"

theUUID="012FF32D-4C4B-4474-8C94-D9142A8ABCFF"
# theUUID=$(uuidgen)

# Aliases
jamf_helper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
PlistBuddy="/usr/libexec/PlistBuddy -c"

# Identify location of jamf binary.
jamf_binary=$(/usr/bin/which jamf)
if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/sbin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
fi

# Check for signature template file
if [[ ! -f "$signatureTemplate" ]]; then
	echo "error: template not found at: $signatureTemplate"
	exit 1
fi

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
theOSVersion=$(/usr/bin/sw_vers -productVersion)
if [[ $theOSVersion==10.11.* ]]; then
	baseFolder="${theHome}Library/Mail/V3"
else
	baseFolder="${theHome}Library/Mail/V2"
fi

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

MY_UUID="$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')"
if [ -z "${MY_UUID}" ]; then
    echo "Couldn't find system UUID"
    exit 1
fi

JSS_CONNECTION="$($jamf_binary checkJSSConnection)"
if [ ! ${JSS_CONNECTION} ]; then
    echo "No connection to JSS"
    exit 1
fi

JSS_BASEURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
if [ -z "${JSS_BASEURL}" ]; then
    echo "Couldn't find JSS base URL"
    exit 1
fi

JSS_APIURL="${JSS_BASEURL}JSSResource/"
RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${JSS_API_USER}":"${JSS_API_PASS}" "${JSS_APIURL}computers/udid/${MY_UUID}/subset/location")
if [ -z "${RESULT_XML}" ]; then
    echo "Couldn't get XML from JSS webservice"
    exit 1
fi

theName="$(echo "${RESULT_XML}" | xpath "string(/computer/location/real_name)" 2> /dev/null)"
theTitle="$(echo "${RESULT_XML}" | xpath "string(/computer/location/position)" 2> /dev/null)"
thePhone="$(echo "${RESULT_XML}" | xpath "string(/computer/location/phone)" 2> /dev/null)"

fileMailSignature="${folderSignatures}/${theUUID}.mailsignature"
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
cat "$signatureTemplate" | sed "s^PHONE^$thePhone^g" | sed "s^USERNAME^$theName^g" |  sed "s^TITLE^$theTitle^g" > "$fileMailSignature"
chown "$theUID" "$fileMailSignature"
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
pkill -U "$theUID" cfprefsd
sleep 5
"$jamf_helper" -windowType utility -icon "$dialogIconPath" -title "$dialogTitle" -description "$messageDone" -button1 "OK"
/usr/bin/su -l "$theUID" -c "open /Applications/Mail.app"

exit 0