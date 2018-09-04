#!/bin/bash

source /usr/local/etc/monitor-modem.cfg

print_syslog() {
    logger --id=$$ -t monitor-modem "$1"
}


test_connectivity() {
    # Returns 0 if *any* host responds to ping.
    # If no hosts respond to ping, returns 1.
    for HOST in $HOSTS
    do ping -c 4 $HOST > /dev/null
       if [ "$?" = "0" ]
       then if [ "$VERBOSELOGGING" = "1" ]
	    then print_syslog "Connectivity check passed while pinging $HOST."
	    fi
	    return 0
       fi
    done
    print_syslog "Connectivity check failed."
    return 1
}

init_gpio() {
    # This script assumes that power to the modem is run through the C/NC
    # terminals of a relay, and that the relay can be energized
    # by applying +3.3V to $RELAYPIN. Controlling GPIO pins requires root
    # or gpio group membership on Raspbian.
    # Initialize the pin.
    print_syslog "Initializing GPIO pin $RELAYPIN."
    # If the following line is run more than once, it generates an ugly
    # error in syslog when run under systemd.
    echo "$RELAYPIN" > /sys/class/gpio/export &> /dev/null
    echo "out" > "/sys/class/gpio/gpio${RELAYPIN}/direction"
}

reset_modem() {
    # Cut power to the modem for ten seconds.
    print_syslog "Power cycling modem for 10 seconds."
    echo "1" > "/sys/class/gpio/gpio${RELAYPIN}/value"
    sleep 10
    echo "0" > "/sys/class/gpio/gpio${RELAYPIN}/value"
}


init_gpio

# Sometimes it takes a few seconds for DHCP to get an IP and bring up the
# network interface. Running ping before that happens results in a very quick
# failure, causing the script to power cycle the modem unnecessarily. Sleeping
# for a short period of time works around that problem.
sleep 30

while true
do test_connectivity
   if [ "$?" = "0" ]
   then sleep 300
	continue
   else
       # Sometimes the connectivity check will fail, but the modem will recover
       # on its own within seconds or minutes. Because it can take up to 10
       # minutes for the modem to recover from a hard reboot, we give it one
       # more chance to come back on its own first.
       sleep 300
       test_connectivity
       if [ "$?" = "0" ]
       then sleep 300
	    continue
       else
	   reset_modem
	   sleep 1800
       fi
   fi
done
