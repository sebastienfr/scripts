#!/usr/bin/env bash
PROG_NAME=`basename $0`
#LOG_FILE="/opt/certrenew/$PROG_NAME.log"
# Disable logging
LOG_FILE=/dev/null
######Main#####
echo ---------------------------------- >> $LOG_FILE
echo `date` >> $LOG_FILE
rm /home/pi/domoticz/server_cert.pem
cat /etc/letsencrypt/live/home.sebastienfr.fr/privkey.pem >> /home/pi/domoticz/server_cert.pem
cat /etc/letsencrypt/live/home.sebastienfr.fr/fullchain.pem >> /home/pi/domoticz/server_cert.pem
/etc/init.d/domoticz.sh restart
