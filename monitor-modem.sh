#!/bin/bash

# Which pin controls the relay that cuts power to the modem?
#
# On a keyestudio ks0212 hat, the relay mappings are as follows:
# J2: pin 4
# J3: pin 22
# J4: pin 6
# J5: pin 26

RELAYPIN="22"

# These hosts will be pinged to check the Internet connection.
# If *all* of them fail to respond, then the Internet connection will
# be considered down. Accordingly, it is important to choose hosts that
# are almost always up and that never change their IPs (so that a failure
# of the ISP's DNS server will not result in the modem being spuriously
# power cycled). A small assortment of public DNS servers are the logical
# choice.

# Google DNS: 8.8.8.8
# Verisign DNS: 64.6.64.6
# OpenDNS: 208.67.222.222

HOSTS="8.8.8.8 64.6.64.6 208.67.222.222"

print_syslog() {
    logger --id=$$ -t monitor-modem "$1"
}


test_connectivity() {
    # Returns 0 if *any* host responds to ping.
    # If no hosts respond to ping, returns 1.
    for HOST in $HOSTS
    do ping -c 4 $HOST > /dev/null
       if [ "$?" = "0" ]
       then print_syslog "Connectivity check passed while pinging $HOST."
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
   if [ $? = "0" ]
   then sleep 300
	continue
   fi
   reset_modem
   sleep 1800
done
