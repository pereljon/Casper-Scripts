#!/bin/sh
find /var/log/ -type f -delete
find /Library/Logs/ -type f -delete
#change next one to find with path
rm -rf /Users/*/Library/Logs/*
exit 0