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

keep_link_up() {
    while true
    do test_connectivity
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
    done
}

switch_to_keep_link_up() {
    # In case we are switching from keep_modem_off mode, give the modem time
    # to come up before checking the connection.
    power_on_modem
    sleep 1800 &
    wait $! &> /dev/null
    
    keep_link_up &
}

switch_to_keep_modem_off() {
    jobs -r | grep keep_link_up > /dev/null
    if [ "$?" = 0 ]
    then KEEP_LINK_UP_PID=$(jobs -rl | grep keep_link_up|awk '{print $2}')
	 kill $KEEP_LINK_UP_PID
    fi
    power_off_modem
}

exit_cleanly() {
    kill $(jobs -p) &> /dev/null
    print_syslog "Exiting."
    exit 0
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
    echo "$RELAYPIN" > /sys/class/gpio/export 2> /dev/null
    echo "out" > "/sys/class/gpio/gpio${RELAYPIN}/direction"
}

# monitor-modem can be placed into one of two modes by sending it signals. In
# the default mode, keep_link_up, monitor-modem checks for network connectivity
# and power cycles the modem if the network has been out for too long. In the
# alternate mode, keep_modem_off, it powers down the modem until another signal
# is received setting it back to the default mode. This is designed to allow
# Internet access to be scheduled with cron.
init_signal_control() {
    trap switch_to_keep_modem_off SIGUSR1
    trap switch_to_keep_link_up SIGUSR2
    trap exit_cleanly INT TERM EXIT
}

init_all() {
    init_gpio
    init_signal_control
}

init_all

# Sometimes it takes a few seconds for DHCP to get an IP and bring up the
# network interface. Running ping before that happens results in a very quick
# failure, causing the script to power cycle the modem unnecessarily. Sleeping
# for a short period of time works around that problem.
sleep 30

switch_to_keep_link_up
while true
do sleep 3600 &
   # wait is necessary so that the main loop will not block the reception and
   # processing of signals.
   wait $! &>/dev/null
done
