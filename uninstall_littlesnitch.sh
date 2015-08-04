#!/bin/bash
launchctl unload /Library/LaunchDaemons/at.obdev.*
launchctl unload /Library/LaunchAgents/at.obdev.*
rm /Library/LaunchDaemons/at.obdev.*
rm /Library/LaunchAgents/at.obdev.*
exit 0