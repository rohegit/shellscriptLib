#!/bin/sh
# =========================
# Notifies a given user via pushover (https://pushover.net) when a specified host goes online
# -------------------
# THIS SCRIPT DEPENDS ON checkHoststatus.sh
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
# File the status is logged to
HOSTSFILE="/www/hosts.xml"
# Pusover parameters
PUSHOVERTOKEN="abc123"
PUSHOVERUSER="user123"

# Has the host been online for long enough?
shouldNotificationBeSent() {
	HOST=$1
	TIMEONLINE=`xmlstarlet sel -t -v "//host[@id='$HOST']/status/uptime" -v . -n <$HOSTSFILE`
	ALREADYNOTIFIED=`xmlstarlet sel -t -v "//host[@id='$HOST']/status/notified" -v . -n <$HOSTSFILE`
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
	TIMEONLINE=`xmlstarlet sel -t -v "//host[@id='$HOST']/status/uptime" -v . -n <$HOSTSFILE`

	# We sent a notification so set the status
	xmlstarlet ed -u "//host[@id='$HOST']/status/uptime" -v "$TIMEONLINE" "$HOSTSFILE"
	xmlstarlet ed -u "//host[@id='$HOST']/status/power" -v "1" "$HOSTSFILE"
	xmlstarlet ed -u "//host[@id='$HOST']/status/notified" -v "1" "$HOSTSFILE"
}

# Should a notification be sent
calcUptimeAndSendNotification() {
	HOSTS=($(xmlstarlet sel -t -m "//hosts/host/name" -v . -n < "$HOSTSFILE"))
	for HOST in "${HOSTS[@]}"; do
		SENDNOTIFICATION=`shouldNotificationBeSent $HOST`
	
		if [ "$SENDNOTIFICATION" -eq "1" ]; then
			sendNotification "$HOST"
			updateNotificationStatus "$HOST"
			echo "$HOST: Notification sent"
		fi
	done
}

calcUptimeAndSendNotification