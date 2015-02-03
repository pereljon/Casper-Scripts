#!/bin/bash

CURL_OPTIONS="--silent --connect-timeout 30"
MY_API_USER="JSS_API_USERNAME"
MY_API_PASS="JSS_API_PASSWORD"
MY_JSS_BASEURL=$( /usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf jss_url)

if [ -n "${MY_JSS_BASEURL}" ]; then
	MY_JSS_APIURL="${MY_JSS_BASEURL}JSSResource/"
	MY_SERIAL_NUMBER=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $4}')
	if [ -n "${MY_SERIAL_NUMBER}" ]; then
		RESULT_XML=$(/usr/bin/curl ${CURL_OPTIONS} --header "Accept: application/xml" --request GET --user "${MY_API_USER}":"${MY_API_PASS}" "${MY_JSS_APIURL}computers/serialnumber/${MY_SERIAL_NUMBER}/subset/general&location&hardware")
		if [ -n "${RESULT_XML}" ]; then
			MANAGED=$(echo "${RESULT_XML}" | xpath "string(/computer/general/remote_management/managed)" 2> /dev/null )			
			USERNAME=$(echo "${RESULT_XML}" | xpath "string(/computer/general/remote_management/management_username)" 2> /dev/null )			
			BARCODE1=$(echo "${RESULT_XML}" | xpath "string(/computer/general/barcode_1)" 2> /dev/null )			
			COMPUTER_MODEL=$(echo "${RESULT_XML}" | xpath "string(/computer/hardware/model)" 2> /dev/null)
			ASSET_TAG=$(echo "${RESULT_XML}" | xpath "string(/computer/general/asset_tag)" 2> /dev/null)
			TITLE=$(echo "${RESULT_XML}" | xpath "string(/computer/location/position)" 2> /dev/null)
			DEPARTMENT=$(echo "${RESULT_XML}" | xpath "string(/computer/location/department)" 2> /dev/null)
			REAL_NAME=$(echo "${RESULT_XML}" | xpath "string(/computer/location/real_name)" 2> /dev/null)
			NAME_WORDS=$(echo "${REAL_NAME}" | wc -w 2> /dev/null )
			FIRST_NAME=$(echo "${REAL_NAME}" | awk '{print $1}' 2> /dev/null )
			LAST_INIT=$(echo "${REAL_NAME}" | cut -d ' ' -f ${NAME_WORDS} 2> /dev/null | cut -b 1 2> /dev/null )
			case "$DEPARTMENT" in
				'Account Management')
					TITLE_A="ACM"
					;;
				*Accounting*)
					TITLE_A="ACT"
					;;
				*Strategy*)
					TITLE_A="STR"
					;;
				'Operations')
					TITLE_A="OPS"
					;;
				'Public Relations')
					TITLE_A="PR"
					;;
				*)
					TITLE_A="???"
					;;
			esac
			case "$TITLE" in
				"Project Manager")
					TITLE_B="STF"
					;;
				"CFO")
					TITLE_B="CFO"
					;;
				"Head of"*)
					TITLE_B="DIR"
					;;
				*Freelanc*)
					TITLE_B="FRE"
					;;
				*"Executive Assistant"*)
					TITLE_B="EA"
					;;
				*Director*)
					TITLE_B="DIR"
					;;
				*)
					TITLE_B="STF"
					;;
				esac
			case "$COMPUTER_MODEL" in
				*MacBook*Air*)
					TITLE_C="MBA"
					;;
				*MacBook*Pro*)
					TITLE_C="MBP"
					;;
				*MacBook*)
					TITLE_C="MB"
					;;
				*MacPro*)
					TITLE_C="MP"
					;;
				*iMac*)
					TITLE_C="IMAC"
					;;
				*mini*)
					TITLE_C="MINI"
					;;
				*)
					TITLE_C="???"
					;;
			esac
			if [ -z "${MANAGED}" ]; then
				NEW_NAME="${MY_SERIAL_NUMBER}"
			elif [ -n "${REAL_NAME}" ] && [ -n "${BARCODE1}" ]; then
				NEW_NAME="${TITLE_A}-${BARCODE1}-${FIRST_NAME}${LAST_INIT}-${ASSET_TAG}-${TITLE_C}"
			elif [ -n "${BARCODE1}" ]; then
				NEW_NAME="${TITLE_A}-${BARCODE1}-${ASSET_TAG}-${TITLE_C}"
			elif [ -n "${REAL_NAME}" ]; then
				NEW_NAME="${TITLE_A}-${TITLE_B}-${FIRST_NAME}${LAST_INIT}-${ASSET_TAG}-${TITLE_C}"
			else
				NEW_NAME="VBP-${ASSET_TAG}-${TITLE_C}"
			fi
			sudo /usr/sbin/jamf setComputerName -name "${NEW_NAME}"
		else
			echo "Error: getting computer information from ${MY_JSS_BASEURL}" 1>&2
			exit 1
		fi
	else
		echo "Error: unable to read serial number" 1>&2
		exit 1
	fi
else
	echo "Error: unable to read jss base url" 1>&2
	exit 1
fi
exit 0