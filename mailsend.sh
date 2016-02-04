#!/bin/bash
###
#
# mailsend.sh : Casper script to send email to user using authenticated SMTP with SSL.
# https://github.com/pereljon/Casper-Scripts/blob/master/mailsend.sh
# Info: Message input can be a text file or actual message.
# Requires: /usr/local/bin/mailsend from: https://github.com/muquit/mailsend
#
# Jonathan Perel, 2016-02-03
# Version: 1.2
#
###

### SET AUTHENTICATION BELOW ###
# JSS API user and password
JSS_API_USER="JSS_USER"
JSS_API_PASS="JSS_PASSWORD"
# Mail server, user and password
SMTP_SERVER="SMTP_SERVER"
SMTP_PORT="465"
SMTP_USER="SMTP_USER"
SMTP_PASSWORD="SMTP_PASSWORD"

### INPUT VARIABLES FROM POLICY
# From email address
FROM="$4"
# Email subject
SUBJECT="$5"
# Either UNIX path to a text file with the email message, or actual text of email message.
MESSAGE="$6"

jamf_helper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# Identify location of jamf binary.
jamf_binary=$(/usr/bin/which jamf)
if [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ ! -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/sbin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ ! -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
elif [[ "$jamf_binary" == "" ]] && [[ -e "/usr/sbin/jamf" ]] && [[ -e "/usr/local/bin/jamf" ]]; then
 jamf_binary="/usr/local/bin/jamf"
fi

CURL_OPTIONS="--silent --connect-timeout 30"
MAILSEND="/usr/local/bin/mailsend"

JSS_CONNECTION="$($jamf_binary checkJSSConnection)"
if [ ! ${JSS_CONNECTION} ]; then
    echo "No connection to JSS"
    exit 1
fi

JSS_BASEURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)
if [ -z "${JSS_BASEURL}" ]; then
    echo "Couldn't find JSS base URL"
    exit 2
fi

JSS_APIURL="${JSS_BASEURL}JSSResource/"
MY_UUID="$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')"
if [ -z "${MY_UUID}" ]; then
    echo "Couldn't find system UUID"
    exit 3
fi

RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${JSS_API_USER}":"${JSS_API_PASS}" "${JSS_APIURL}computers/udid/${MY_UUID}/subset/location")
if [ -z "${RESULT_XML}" ]; then
    echo "Couldn't get XML from JSS webservice"
    exit 4
fi

EMAIL_ADDRESS="$(echo "${RESULT_XML}" | xpath "string(/computer/location/email_address)" 2> /dev/null)"
if [ -z "${EMAIL_ADDRESS}" ]; then
    echo "Couldn't get email address from XML"
    exit 6
fi

if [ -f "${MESSAGE}" ]; then
    # $MESSAGE is a file, send file as message body
    ${MAILSEND} -smtp ${SMTP_SERVER} +cc -port ${SMTP_PORT} -auth -ssl -user ${SMTP_USER} -pass "${SMTP_PASSWORD}" -t ${EMAIL_ADDRESS} -f ${FROM} -sub "${SUBJECT}" -msg-body "${MESSAGE}"
elif [ -n "$MESSAGE" ]; then
    # $MESSAGE is not a file, send as text
    ${MAILSEND} -smtp ${SMTP_SERVER} +cc -port ${SMTP_PORT} -auth -ssl -user ${SMTP_USER} -pass "${SMTP_PASSWORD}" -t ${EMAIL_ADDRESS} -f ${FROM} -sub "${SUBJECT}" <<EOF
${MESSAGE}
EOF
fi

exit 0