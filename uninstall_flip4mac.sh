#!/bin/sh

# remove historical files

oldUserGuide="Flip4Mac WMV Player User Guide.pdf"
/bin/rm ~/Desktop/"$oldUserGuide"

prefPaneNameOnDesktop="Flip4Mac WMV Registration"
/bin/rm ~/Desktop/"$prefPaneNameOnDesktop"

preferencesPath="/Library/Preferences"

internetPluginsPath="/Library/Internet Plug-Ins"
windozeMediaPluginName="Windows Media Plugin"
disabledFolderName="Disabled Plug-Ins"
appFolderPath="/Applications/Flip4Mac"

/bin/rm -rf /Applications/WMV\ Player.app/

# New application files and registration link

/bin/rm -rf /Applications/Flip\ Player.app/
/bin/rm -rf "$appFolderPath"/WMV\ Player.app/
/bin/rm -rf "$appFolderPath"/ReadMe.rtfd
/bin/rm "$appFolderPath"/Users\ Guide.rtf
/bin/rm "$appFolderPath"/Flip4Mac\ WMV\ User\ Guide.pdf
/bin/rm "$appFolderPath"/Flip4Mac\ WMV\ Player\ User\ Guide.pdf
/bin/rm "$appFolderPath"/Flip4Mac\ User\ Guide.pdf
/bin/rm "$appFolderPath"/WMV\ Upgrade

# Remove QT components

/bin/rm -rf /Library/QuickTime/Flip4Mac\ WMV\ Import.component/ 
/bin/rm -rf /Library/QuickTime/Flip4Mac\ WMV\ Advanced.component/ 
/bin/rm -rf /Library/QuickTime/Flip4Mac\ WMV\ Export.component/ 


# Remove Audio-Plugin-based Core Audio Components

/bin/rm -rf /Library/Audio/Plug-Ins/Components/Flip4Mac\ WMA\ Import.component/


# Remove web browser plug-ins

/bin/rm -rf "$internetPluginsPath"/Flip4Mac\ WMV\ Plugin.plugin/ 
/bin/rm -rf "$internetPluginsPath"/Flip4Mac\ WMV\ Plugin.webplugin/ 

/bin/rm -rf "$internetPluginsPath/$disabledFolderName"/Flip4Mac\ WMV\ Plugin.plugin/ 
/bin/rm -rf "$internetPluginsPath/$disabledFolderName"/Flip4Mac\ WMV\ Plugin.webplugin/ 

# move windows media player back into place

if [ -d "$internetPluginsPath/$disabledFolderName/$windozeMediaPluginName" ] ; then
	if [ ! -d "$internetPluginsPath/$windozeMediaPluginName" ] ; then
		/bin/mv -f "$internetPluginsPath/$disabledFolderName/$windozeMediaPluginName" "$internetPluginsPath/"
	fi
fi

# remove the disabled plug-ins folder if it is empty
/bin/rm "$internetPluginsPath/$disabledFolderName/.DS_Store"
/bin/rmdir "$internetPluginsPath/$disabledFolderName"

# old prefpane
/bin/rm -rf /Library/PreferencePanes/WmvPlayer.prefPane/ 
# new prefpane
/bin/rm -rf /Library/PreferencePanes/Flip4Mac\ WMV.prefPane/ 
# WmvSetPref tool
/bin/rm -rf ~/Library/Application\ Support/Flip4Mac/WmvSetPref

# Package receipts

/bin/rm -rf /Library/Receipts/Flip4Mac\ Web\ Plugins.pkg/
/bin/rm -rf /Library/Receipts/Flip4Mac\ QuickTime\ Components.pkg/
/bin/rm -rf /Library/Receipts/Flip4Mac\ WMV\ Player\ Installer.pkg/
/bin/rm -rf /Library/Receipts/Flip4Mac\ Uninstaller.pkg/

# Leopard and newer uses a new method to remove receipts (leave the old method above to clean out any old receipts too)

osMinorVers=`sw_vers -productVersion| cut -d '.' -f 2`

if [ $osMinorVers -ge 5 ]; then
	/usr/sbin/pkgutil --forget net.telestream.wmv.components
	/usr/sbin/pkgutil --forget net.telestream.wmv.plugins
fi

# Change mms URLs back to windows media player
/usr/bin/defaults write com.apple.LaunchServices LSHandlers -array-add '<dict><key>LSHandlerRoleAll</key><string>com.microsoft.mediaplayer</string><key>LSHandlerURLScheme</key><string>mms</string></dict>'

# Remove the TSLicense.framework. It is no longer used by any other products.
/bin/rm -rf /Library/Frameworks/TSLicense.framework
/bin/rm -rf ~/Library/Frameworks/TSLicense.framework

# Final clean up: remove the uninstaller and app folder
/bin/rm -f "$appFolderPath"/Flip4Mac\ Uninstaller.pkg
/bin/rm -rf "$appFolderPath"/Flip4Mac\ Uninstaller.pkg/
/bin/rm -rf "$appFolderPath"/Flip4Mac\ WMV\ Uninstaller.pkg/
/bin/rm "$appFolderPath/.DS_Store"
/bin/rmdir "$appFolderPath"
/bin/rm -rf "$appFolderPath"

exit 0;

