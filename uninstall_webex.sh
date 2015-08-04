#!/bin/sh
find /Users -path "*/Library/Application Support/*" -name "WebEx Folder" -exec rm -rf {} \;
find /Users -path "*/Library/Internet Plug-Ins/*" -name "WebEx*.plugin" -exec rm -rf {} \;
exit 0

