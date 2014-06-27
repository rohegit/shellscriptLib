#!/bin/sh
# =========================
# Notifies a given user via pushover (https://pushover.net) when a specified host goes online
# -------------------
# THIS SCRIPT DEPENDS ON checkHostState.sh
# You should call it by creating a cronjob
# =========================

# We do not want to notify if there is nothing to be notified of
TONOTIFY="0"	
# Real uptime of host
UPTIME="0"
# How long has the host to be online before we send a notification (minutes)
UPTIMEBEFORENOTIFICATION="10"
# List of hosts which you like to watch. Separated by spaces
HOSTSTOWATCH=( host1 host2 host3 )
# File the state is logged to
WATCHFILE="/www/hoststate.xml"
# Pusover parameters
PUSHOVERTOKEN="abc123"
PUSHOVERUSER="user123"

# Has the host been online for long enough?
shouldNotificationBeSent() {
	HOST=$1
	TIMEONLINE=`xmlstarlet sel -t -v "//host[@id='$HOST']/uptime" -v . -n <$WATCHFILE`
	ALREADYNOTIFIED=`xmlstarlet sel -t -v "//host[@id='$HOST']/notified" -v . -n <$WATCHFILE`
	NOW=`date "+%Y-%m-%d %H:%M"`;
	TIMENOW=`date -d "$NOW" +%s`
	TIMEUPSEC=`expr $TIMENOW - $TIMEONLINE`; 
	UPTIME=`expr $TIMEUPSEC / 60`

	# If uptime is higher than the set UPTIMEBEFORENOTIFICATION
	if [ "$UPTIME" -gt "$UPTIMEBEFORENOTIFICATION" ] && [ "$ALREADYNOTIFIED" -eq "0" ]; then
		TONOTIFY="1"
	fi

	echo $TONOTIFY
}

# Method to send a notification.
# For this to work you need to have pushover installed (see https://pushover.net)
sendNotification() {
	HOST=$1
	curl -s -F "token=$PUSHOVERTOKEN" -F "user=$PUSHOVERUSER" -F "message=$HOST has been  up for $UPTIME minutes" https://api.pushover.net/1/messages.json
}

# We need to know which notifications we have already sent
updateNotificationStatus() {
	HOST=$1
	TIMEONLINE=`xmlstarlet sel -t -v "//host[@id='$HOST']/uptime" -v . -n <$WATCHFILE`

	# We sent a notification so set the status
	xmlstarlet ed -u "//host[@id='$HOST']/uptime" -v "$TIMEONLINE" "$WATCHFILE"
	xmlstarlet ed -u "//host[@id='$HOST']/state" -v "1" "$WATCHFILE"
	xmlstarlet ed -u "//host[@id='$HOST']/notified" -v "1" "$WATCHFILE"
}

# Should a notification be sent
calcUptimeAndSendNotification() {
	for HOST in "${HOSTSTOWATCH[@]}"; do
		SENDNOTIFICATION=`shouldNotificationBeSent $HOST`
	
		if [ "$SENDNOTIFICATION" -eq "1" ]; then
			sendNotification "$HOST"
			updateNotificationStatus "$HOST"
			echo "$HOST: Notification sent"
		fi
	done
}

calcUptimeAndSendNotification