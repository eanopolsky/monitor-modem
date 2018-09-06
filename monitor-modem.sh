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
    if [ "$VERBOSELOGGING" = "1" ]
    then print_syslog "Initializing GPIO pin $RELAYPIN."
    fi
    # If the following line is run more than once, it generates an ugly
    # error in syslog when run under systemd.
    echo "$RELAYPIN" > /sys/class/gpio/export &> /dev/null
    echo "out" > "/sys/class/gpio/gpio${RELAYPIN}/direction"
}

# monitor-modem can be placed into one of two modes by sending it signals. In
# the default mode, keep_link_up, monitor-modem checks for network connectivity
# and power cycles the modem if the network has been out for too long. In the
# alternate mode, keep_modem_off, it powers down the modem until another signal
# is received setting it back to the default mode. This is designed to allow
# Internet access to be scheduled with cron.
init_signal_control() {
    OPERATIONMODE="keep_link_up"
    trap OPERATIONMODE="keep_modem_off" SIGUSR1
    trap OPERATIONMODE="keep_link_up" SIGUSR2
}

init() {
    init_gpio
    init_signal_control
}

power_off_modem() {
    print_syslog "Powering off modem."
    echo "1" > "/sys/class/gpio/gpio${RELAYPIN}/value"
}

power_on_modem() {
    print_syslog "Powering on modem."
    echo "0" > "/sys/class/gpio/gpio${RELAYPIN}/value"
}

reset_modem() {
    # Cut power to the modem for ten seconds.
    print_syslog "Power cycling modem for 10 seconds."
    power_off_modem
    sleep 10
    power_on_modem
}

init

# Sometimes it takes a few seconds for DHCP to get an IP and bring up the
# network interface. Running ping before that happens results in a very quick
# failure, causing the script to power cycle the modem unnecessarily. Sleeping
# for a short period of time works around that problem.
sleep 30

while true
do if [ "$OPERATIONMODE" = "keep_link_up" ]
   then test_connectivity
	if [ "$?" = "0" ]
	then sleep 300
	     continue
	else
	    # Sometimes the connectivity check will fail, but the modem
	    # will recover on its own within seconds or minutes. Because
	    # it can take up to 10 minutes for the modem to recover from
	    # a hard reboot, we give it one more chance to come back on
	    # its own first.
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
   elif [ "$OPERATIONMODE" = "keep_modem_off" ]
   then power_off_modem
	while [ "$OPERATIONMODE" = "keep_modem_off" ]
	do sleep 60
	done
	power_on_modem
	# Give the modem time to reestablish a connection before considering
	# power cycling it in keep_link_up mode:
	sleep 1800 
   else print_syslog "Unsupported operation mode."; exit 1
   fi
done
