#!/bin/sh
# =========================
# Executes any command on a remote host and logs it 
#
# Parameters: HOST "Command to execute" [return the output]
# Example: execRemoteCommand.sh host1 "ls -l /tmp" 1
# =========================

COMMANDLOGFILE="/www/commands/last_command_$1.txt"
COMMANDOUTPUTLOGFILE="/www/commands/last_output_$1.txt"
# The key which is used to login on the host the commands are executed on
SSHKEYPATH="/root/rsa_host_key"

# Return the output
returnTheOutputLog() {
	# If we want to return the output, we have to specify a third parameter
	if [ "$1" -eq "1" ]; then
		cat "$COMMANDOUTPUTLOGFILE"
	fi
}

# Execute the remote command on the host
execRemoteCommand() {
	# If the directory used to log our executed commands does not exist, create it
	COMMANDDIR=`dirname "$COMMANDLOGFILE"`
	if [ ! -d "$COMMANDDIR" ]; then
	  mkdir "$COMMANDDIR"
	fi

	# Log the executed command
	echo "$2" > "$COMMANDLOGFILE"

	# Execute the command on the remote host
	ssh -i "$SSHKEYPATH" root@$1 "bash -c \"$2\"" > "$COMMANDOUTPUTLOGFILE"
}

execRemoteCommand $1 $2
returnTheOutputLog $3
