#!/bin/bash
# Hide users with ID below 500
defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES
exit 0