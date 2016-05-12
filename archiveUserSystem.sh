#!/bin/bash
# IP/DNS Address of server to archive to
serverAddress="$4"
# Login username at archive server
serverUser="$5"
# Archive path on server
serverPath="$6"
# Private SSH key location for user@server 
serverKey="$7"
# Rsync exclude file location
excludeFile="$8"

server="${serverUser}@${serverAddress}"
sshOptions="-i ${serverKey} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
serverCommand="ssh -q ${sshOptions} ${server}"

# Check that server path exists (and we can connect to server)
pathExists="$(${serverCommand} "if test -d \"${serverPath}\"; then echo \"1\"; fi")"
if [ -z "${pathExists}" ]; then
	echo "Server path ${serverPath} not found on ${server}"
	rm "${serverKey}"
	exit 1
fi

# Check that archive user is logged in
#theUser="$(who | grep console | awk '{print $1}')"
#if [ "$theUser" == "admin" ] || [ "$theUser" == "root" ] || [ "$theUser" == "jssuser" ] || [ -z "$theUser" ]; then
#	echo "Bad archive user: ${theUser}"
#	rm "${serverKey}"
#	exit 1
#fi
# Check user folder exists
#theUserFolder="/Users/${theUser}"
#pathExists="$(if test -d "${theUserFolder}"; then echo "1"; fi)"
#if [ -z "${pathExists}" ]; then
#	echo "No user folders to archive at: ${pathExists}"
#	rm "${serverKey}"
#	exit 1
#fi

theFolders="$(ls -1 /Users/ | grep -v Guest | grep -v jssuser | grep -v Shared | grep -v admin | grep -v .localized | grep -v root)"
if [ -z "${theFolders}" ]; then
	echo "No user folders to archive"
	rm "${serverKey}"
	exit 1
fi

#if [[ ! ${theFolders} =~ ${theUser} ]]; then
#	echo "User folder: ${theUserFolder} not found in /Users"
#	rm "${serverKey}"
#	exit 1
#fi

echo "Archiving:"
echo "${theFolders}"

# Create archive folder
theDate="$(date +"%Y%m%d")"
theComputer="$(scutil --get ComputerName)"
#theArchivePath="${serverPath}/${theDate}_${theUser}"
theArchivePath="${serverPath}/${theDate}_${theComputer}"
echo "Archiving to ${theArchivePath}"
pathExists="$(${serverCommand} "if test -d \"${theArchivePath}\"; then echo \"1\"; fi")"
if [ -z "${pathExists}" ]; then
	echo "Creating archive path ${theArchivePath} on ${server}"
	result="$(${serverCommand} "mkdir \"${theArchivePath}\"")"
	pathExists="$(${serverCommand} "if test -d \"${theArchivePath}\"; then echo \"1\"; fi")"
	if [ -z "${pathExists}" ]; then
		echo "Failed creating archive path: ${theArchivePath}"
		rm "${serverKey}"
		exit 1
	fi
else
	echo "Archive path ${theArchivePath} already exists on ${server}"	
fi

echo "Starting:"
for nextFolder in ${theFolders}; do
	fromFolder="/Users/${nextFolder}"
	echo "Archive from: ${fromFolder}"
	rsync -e "ssh ${sshOptions}" -rlptDm --extended-attributes --exclude-from="${excludeFile}" "/Users/${nextFolder}" "${server}:${theArchivePath}"
done

echo "Done"
archiveSize="$(${serverCommand} "du -sh \"${theArchivePath}\"")"
echo "Archive size: ${archiveSize}"

rm "${serverKey}"
exit 0