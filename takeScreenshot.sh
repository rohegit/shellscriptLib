#!/bin/sh
# =========================
# Takes a screenshot on a host with an installed X-Server (Linux) and transfers it to a location you can easily grab it from
# ----------------
# You should call it by creating a cronjob
# =========================

# List of hosts which you like to screenshots of. Separated by spaces
HOSTSTOWATCH=( host1 host2 host3 )
SSHKEYPATH="/root/rsa_host_key"
SCREENSHOTPATH="/www/screenshots"

# You need to have setup authorization of the server on the hosts in the HOSTSTOWATCH-list by certificate
# For instructions please see http://www.linuxproblem.org/art_9.html
for HOST in "${HOSTSTOWATCH[@]}"; do
	HOSTUP=`ping -W 1 -c 2 -q $HOST | grep ", 0% packet loss"`;

	if [ -n "$HOSTUP" ]; then
		# Screenshot will be saved to /tmp
		ssh -i "$SSHKEYPATH" root@$HOST "DISPLAY=:0 XAUTHORITY=/home/user/.Xauthority import -window root /tmp/shot.png" 
	  	scp -i "$SSHKEYPATH" root@$HOST:/tmp/shot.png "$SCREENSHOTPATH/$HOST_shot.png"
	  	echo "$HOST: Screenshot taken"
	fi
done

