#!/bin/sh
# =========================
# Checks the state of specified hosts and logs it to a file so we can see at a glance
# which of our hosts are online. Without a need to directly interact with them.
# The logfile can also be placed in dropbox so there is no need to have remote-access
# to your home-network to see who is online
# ----------------
# You should call it by creating a cronjob
# =========================

# List of hosts which you like to watch. Separated by spaces
HOSTSTOWATCH=( host1 host2 host3 )
# File the state is logged to
WATCHFILE="/www/hoststate.xml"

# How long has the host bee online
calculateUptime() {
	HOST=$1
	TIMEONLINE=`xmlstarlet sel -t -v "//host[@id='$HOST']/uptime" -v . -n <$WATCHFILE`
	TIMENOW=`date "+%d%m%Y%H%M"`
	return `expr $TIMENOW - $TIMEONLINE`
}

# Should we replace the current entry or is there none and therefore should be written first
replaceOrWriteEntry() {
	HOST=$1
	STATE=$2
	TIMEONLINE=$3
	HOSTEXISTS=`xmlstarlet sel -t -v "count(//host[@id='$HOST'])" $WATCHFILE`

	#Only if there is an entry we can replace it
	if [ "$HOSTEXISTS" -gt 0 ]; then
		#sed -i "s/$HOST.*/$HOST=$STATE;$TIMEONLINE;0/" $WATCHFILE
		xmlstarlet ed -u "//host[@id='$HOST']/uptime" -v "$TIMEONLINE" "$WATCHFILE"
		xmlstarlet ed -u "//host[@id='$HOST']/state" -v "$STATE" "$WATCHFILE"

		# If the host is turned off, then we should reset the notification counter
		if [ "$STATE" -eq 0 ]; then
			xmlstarlet ed -u "//host[@id='$HOST']/notified" -v "0" "$WATCHFILE"
		fi
	else
		xmlstarlet ed -s "/hoststate" -t elem -n "hostTMP" -v "" \
		-i "/hoststate/hostTMP" -t attr -n "id" -v "$HOST" \
		-s "//hostTMP" -t elem -n "name" -v "$HOST" \
		-s "//hostTMP" -t elem -n "state" -v "$STATE" \
		-s "//hostTMP" -t elem -n "uptime" -v "$TIMEONLINE" \
		-s "//hostTMP" -t elem -n "notified" -v "0" \
		-r "//hostTMP" -v "host" \
		"$WATCHFILE"
	fi
}

# Check if the host is up
pingHost() {
	HOST=$1
	OLDSTATE=`xmlstarlet sel -t -v "//host[@id='$1']/state" -v . -n <$WATCHFILE`

	# If there is no old state we simply create one
	if [ ! -n "$OLDSTATE" ]; then
		OLDSTATE="0"
		replaceOrWriteEntry "$HOST" "0" "0"
	fi

	# If we can ping the host, we assume ist online
	if [ -n "$(ping -W 1 -c 2 -q $1 | grep ', 0% packet loss')" ]; then
		CURSTATE="1"
	fi

	# Write the new state
	if [ "$OLDSTATE" -eq 0 -a "$CURSTATE" -eq 1 ]; then
		NOW=`date "+%Y-%m-%d %H:%M"`;
		replaceOrWriteEntry "$HOST" "1" $(date -d "$NOW" +%s)
	elif [ "$OLDSTATE" -eq 1 -a "$CURSTATE" -eq 0 ]; then
		replaceOrWriteEntry "$HOST" "0" "0"
	fi

	echo "$HOST - $CURSTATE"
}

# Main-function
checkHostState() {
	# If the file the state is saved to does not exist we create it
	if [ ! -f "$WATCHFILE" ]; then
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > "$WATCHFILE"
		echo "<hoststate>" >> "$WATCHFILE"
		echo "</hoststate>" >> "$WATCHFILE"
	fi

	for HOST in "${HOSTSTOWATCH[@]}"; do
		pingHost $HOST
	done
}

checkHostState