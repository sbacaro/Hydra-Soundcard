#!/bin/sh

DVS_SILENT_INSTALL_FILE="/tmp/DVS_silent_install"

display_alert()
{
	if [ -f "$DVS_SILENT_INSTALL_FILE" ]; then
		echo "1"
		return
	fi
	RESULT=$(eval "./NSAlertLauncher.app/Contents/MacOS/NSAlertLauncher $1")
	if [[ $RESULT == "second" ]]; then
		echo "0"
		return
	fi
	echo "1"
}

delete_silent_install_file()
{
	if [ -f "$DVS_SILENT_INSTALL_FILE" ]; then
		echo "Removing silent install file"
		rm -f $DVS_SILENT_INSTALL_FILE
	fi
}
