#!/bin/bash

DC_PKG_ID="com.audinate.dante.pkg.DanteController"
DC_APP_PATH="/Applications/Dante Controller.app"
INSTALL_LOG="/var/log/install.log"

display_alert()
{
	if [ -n "$COMMAND_LINE_INSTALL" ]; then
		echo "0"
		return
	fi
	RESULT=$(eval "./NSAlertLauncher.app/Contents/MacOS/NSAlertLauncher $1 'icon' 'icon.icns'")
	if [[ $RESULT == "second" ]]; then
		echo "2"
		return
	fi
	echo "1"
}
