#!/bin/bash
# Uninstall AJA Drivers

# Unload LaunchAgents and LaundDaemons
launchctl unload /Library/LaunchAgents/com.aja*
launchctl unload /Library/LaunchDaemons/com.aja*

rm -rf "/Applications/Adobe Photoshop CC 2014/Plug-ins/AJACapture.plugin"
rm -rf "/Applications/Adobe Photoshop CC 2014/Plug-ins/AJAExport.plugin"
rm -rf "/Applications/Adobe After Effects CC 2014/Plug-ins/AJA"
# /Applications/Adobe After Effects CC 2014/Plug-ins/AJA/AJAEmp.plugin
rm -rf /Applications/AJA*
# /Applications/AJA ControlPanel.app
# /Applications/AJA Control Room.app
# /Applications/AJA Utilities
rm -rf "/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore/AJA"
rm -rf "/Library/Application Support/Final Cut Pro System Support/Custom Settings/Kona*"
rm -rf "/Library/Application Support/Final Cut Pro System Support/Custom Settings/AJA*"
rm -rf "/Library/Application Support/Final Cut Pro System Support/Plugins/AJA Kona RT Enabler.txt"
rm -rf "/Library/Application Support/AJA"
rm -rf "/Library/Application Support/Avid/AVX2_Plug-ins/OpenIO-AJA.acf"
rm -rf /Library/Automator/Kona*
# /Library/Automator/Kona DPX To QT Translator.action
# /Library/Automator/Kona QT To DPX Translator.action
rm -rf /Library/CoreMediaIO/Plug-Ins/DAL/AJA.plugin
rm -rf /Library/CoreMediaIO/Plug-Ins/FCP-DAL/AJA.plugin
rm -rf /Library/Extensions/AJA*
# /Library/Extensions/AJAKONA3G.kext
# /Library/Extensions/AJAKONA3GQuad.kext
# /Library/Extensions/AJANTV2.kext
rm -rf /Library/LaunchAgents/com.aja.*
#/Library/LaunchAgents/com.aja.ajaagent.plist
#/Library/LaunchAgents/com.aja.konaupdater.plist
rm -rf /Library/LaunchDaemons/com.aja.*
# /Library/LaunchDaemons/com.aja.ajadaemon.plist
# /Library/LaunchDaemons/com.aja.cmio.ajaassistant.plist
rm -rf /Library/Preferences/com.aja.*
# /Library/Preferences/com.aja.adobe.plist
# /Library/Preferences/com.aja.avid.plist
# /Library/Preferences/com.aja.cmio.plist
# /Library/Preferences/com.aja.driver.plist
# /Library/Preferences/com.aja.quicktime.plist
rm -rf /Library/QuickTime/AJA*
# /Library/QuickTime/AJACodec.component
# /Library/QuickTime/AJADigitizer.component
# /Library/QuickTime/AJAMuxer.component
# /Library/QuickTime/AJAVideoOutput.component
# /Library/QuickTime/AJAVideoOutputClock.component
# /Library/QuickTime/AJAVideoOutputCodec.component
# /Library/QuickTime/AJAUncompressedCodec.component
rm -rf /usr/libexec/ajad

exit 0