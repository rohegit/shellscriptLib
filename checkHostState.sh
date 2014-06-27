#!/bin/sh
# =========================
# Checks the status of specified hosts and logs it to a file so we can see at a glance
# which of our hosts are online. Without a need to directly interact with them.
# The logfile can also be placed in dropbox so there is no need to have remote-access
# to your home-network to see who is online
# ----------------
# You should call it by creating a cronjob
# =========================

# Config file of the hosts
HOSTSFILE="/www/hosts.xml"

# How long has the host bee online
calculateUptime() {
	HOST=$1
	UPTIME=`xmlstarlet sel -t -v "//host[@id='$HOST']/status/uptime" -v . -n <$HOSTSFILE`
	TIMENOW=`date "+%d%m%Y%H%M"`
	return `expr $TIMENOW - $UPTIME`
}

# Should we replace the current entry or is there none and therefore should be written first
replaceOrWriteEntry() {
	HOST=$1
	POWER=$2
	UPTIME=$3
	HOSTEXISTS=`xmlstarlet sel -t -v "count(//host[@id='$HOST'])" $HOSTSFILE`

	#Only if there is an entry we can replace it
	if [ "$HOSTEXISTS" -gt 0 ]; then
		xmlstarlet ed -u "//host[@id='$HOST']/status/uptime" -v "$UPTIME" "$HOSTSFILE"
		xmlstarlet ed -u "//host[@id='$HOST']/status/status" -v "$POWER" "$HOSTSFILE"

		# If the host is turned off, then we should reset the notification counter
		if [ "$POWER" -eq 0 ]; then
			xmlstarlet ed -u "//host[@id='$HOST']/status/notified" -v "0" "$HOSTSFILE"
		fi
	else
		IP=`ping -W 1 -c 2 -q $HOST | egrep -o '[\(]{0,1}[0-9\.]{7,}[\)]{0,1}' | egrep -o '[0-9\.]+'`
		MAC=`arp $HOST | egrep -o '[0-9a-zA-Z\:]{11,17}'`

		xmlstarlet ed -s "/hosts" -t elem -n "hostTMP" -v "" \
		-i "/hosts/hostTMP" -t attr -n "id" -v "$HOST" \
		-s "//hostTMP" -t elem -n "name" -v "$HOST" \
		-s "//hostTMP" -t elem -n "description" -v "" \
		-s "//hostTMP" -t elem -n "ip" -v "$IP" \
		-s "//hostTMP" -t elem -n "mac" -v "$MAC" \
		-s "//hostTMP" -t elem -n "status" -v "" \
		-s "//hostTMP/status" -t elem -n "power" -v "$POWER" \
		-s "//hostTMP/status" -t elem -n "uptime" -v "$UPTIME" \
		-s "//hostTMP/status" -t elem -n "notified" -v "0" \
		-r "//hostTMP" -v "host" \
		"$HOSTSFILE"
	fi
}

# Check if the host is up
pingHost() {
	HOST=$1
	OLDPOWER=`xmlstarlet sel -t -v "//host[@id='$1']/status/power" -v . -n <$HOSTSFILE`

	# If there is no old power-status we simply create one
	if [ ! -n "$OLDPOWER" ]; then
		OLDPOWER="0"
		replaceOrWriteEntry "$HOST" "0" "0"
	fi

	# If we can ping the host, we assume ist online
	if [ -n "$(ping -W 1 -c 2 -q $1 | egrep ', (0\.)*0% packet loss')" ]; then
		CURPOWER="1"
	fi

	# Write the new status
	if [ "$OLDPOWER" -eq 0 -a "$CURPOWER" -eq 1 ]; then
		NOW=`date "+%Y-%m-%d %H:%M"`;
		replaceOrWriteEntry "$HOST" "1" $(date -d "$NOW" +%s)
	elif [ "$OLDPOWER" -eq 1 -a "$CURPOWER" -eq 0 ]; then
		replaceOrWriteEntry "$HOST" "0" "0"
	fi

	echo "$HOST - $CURPOWER"
}

# Main-function
checkHostStatus() {
	# If the file the status is saved to does not exist we create it
	if [ ! -f "$HOSTSFILE" ]; then
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > "$HOSTSFILE"
		echo "<hosts>" >> "$HOSTSFILE"
		echo "</hosts>" >> "$HOSTSFILE"
	fi

	HOSTS=($(xmlstarlet sel -t -m "//hosts/host/name" -v . -n < "$HOSTSFILE"))
	for HOST in "${HOSTS[@]}"; do
		pingHost $HOST
	done
}

checkHostStatus