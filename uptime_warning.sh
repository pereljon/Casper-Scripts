#!/bin/bash
# Commands required by this script
declare -xi UPDAYS="$4"
declare -x MESSAGE="$5"

declare -x awk="/usr/bin/awk"
declare -x sysctl="/usr/sbin/sysctl"
declare -x perl="/usr/bin/perl"

declare -xi DAY=86400
declare -xi MAXDAYS="$(($UPDAYS * $DAY))"
declare -xi EPOCH="$($perl -e "print time")"
declare -xi UPTIME="$($sysctl kern.boottime | $awk -F'[= ,]' '/sec/{print $6;exit}')"
declare -xi DIFF="$(($EPOCH - $UPTIME))"
declare -xi DAYS="$(($DIFF / $DAY))"

if [ $DIFF -ge $MAXDAYS ] ; then
    RESULT=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "VB&P Support Message" -button1 "OK"  -defaultButton 1 -description "Your computer has not restarted or shut down in $DAYS days.
$MESSAGE" -icon /Library/Application\ Support/JAMF/VBP/VBPLogo.png)
fi
exit 0