#!/usr/bin/env bash
# Mainly inspired by DynHost script given by OVH
# New version by zwindler (zwindler.fr/wordpress)
#
# Initial version was doing  nasty grep/cut on local ppp0 interface
#
# This coulnd't work in a NATed environnement like on ISP boxes
# on private networks.
#
# Also got rid of ipcheck.py thanks to mafiaman42
#
# Code cleanup and switching from /bin/sh to /bin/bash to work around a bug in
# Debian Jessie ("if" clause not working as expected)
#
# This script uses curl to get the public IP, and then uses wget
# to update DynHost entry in OVH DNS
#
# Logfile: ddns.sh.log
#
# Run script every 5 minutes
# crontab -e
# */5 * * * * /opt/ddns/ddns.sh
# run every 5 minutes
#

# Program name
PROG_NAME=`basename $0`

# CHANGE: "HOST", "LOGIN" and "PASSWORD" to reflect YOUR account variables
HOST=DYNHOST.VOTREDOMAIN.FR
LOGIN=VOTREDOMAINOVH-LOGIN
PASSWORD=VOTREMDP

# Log file
LOG_FILE="/opt/ddns/$PROG_NAME.log"
# Disable logging
#LOG_FILE=/dev/null


getip() {
    IP=`curl 4.ifcfg.me`
    OLDIP=`dig +short $HOST`
}

######Main#####
echo ---------------------------------- >> $LOG_FILE
echo `date` >> $LOG_FILE
getip

if [ "$IP" ]; then
    if [ "$OLDIP" != "$IP" ]; then
        echo -n "Old IP: [$OLDIP]" >> $LOG_FILE
        echo "New IP: [$IP]" >> $LOG_FILE
        wget -q -O -- 'http://www.ovh.com/nic/update?system=dyndns&hostname='$HOST'&myip='$IP --user=$LOGIN --password=$PASSWORD
    else
        echo "Notice: IP $HOST [$OLDIP] is identical to WAN [$IP]! No update required." >> $LOG_FILE
    fi
else
    echo "Error: WAN IP not found. Exiting!" >> $LOG_FILE
fi

