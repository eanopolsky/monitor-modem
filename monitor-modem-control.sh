#!/bin/bash

if [ "$#" != "1" ]
then echo "Usage: $0 keep_modem_off"
     echo "or"
     echo "$0 keep_link_up"
     exit 1
fi

systemctl is-active --quiet monitor-modem
if [ "$?" != "0" ]
then echo "Error: service is not running."
     exit 1
fi

MMPID=$(systemctl show -p MainPID monitor-modem|sed -e 's/.*=//')

if [ "$1" = "keep_modem_off" ]
then kill -s SIGUSR1 $MMPID
elif [ "$1" = "keep_link_up" ]
then kill -s SIGUSR2 $MMPID
else echo "Error: Unsupported mode."
fi
