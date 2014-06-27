shellscriptLib
==============
A compilation of bash-scripts to make controlling my home-equipment with the phone a lot easier.
These scripts are best kept on a server inside your home-network and executed with apps like [simpleSSH](http://simplessh.hirmer.me).

# Features

* Check host-status while on the go
* Execute commands on remote hosts
* Send a notification when a host is online for a certain amount of time
* Take screenshots on the remote hosts and show them on your phone-display

# Requirements

* You need [xmlstarlet](http://xmlstar.sourceforge.net) for _checkHostState.sh_ to work.
* **iPhone only**
  * For notifications [pushover](https://pushover.net) is needed


# Installation

* Download the scripts
  * Change the variable _HOSTSTOWATCH_ to contain the hostnames of the hosts you'd like to check
  * Make them executable with _chmod +x *.sh_
* **iPhone only**
  * Download [pushover](https://pushover.net)
  * Create an account
  * Put your credentials in _notifyWhenUp.sh_
* Create a cronjob for _checkHostState.sh_ and _notifyWhenUp.sh_
