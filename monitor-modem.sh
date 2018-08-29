#!/bin/bash

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

test_connectivity() {
    # Returns 0 if *any* host responds to ping.
    # If no hosts respond to ping, returns 1.
    for HOST in $HOSTS
    do ping -c 4 $HOST
       if [ "$?" = "0" ]
       then return 0
       fi
    done
    return 1
}

init_gpio() {
    # This script assumes that power to the modem is run through the C/NC
    # terminals of a relay, and that the relay can be energized
    # by applying +3.3V to GPIO 18. Controlling GPIO pins requires root
    # or gpio group membership on Raspbian.
    # Initialize the pin.
    echo "18" > /sys/class/gpio/export
    echo "out" > /sys/class/gpio/gpio18/direction
}


reset_modem() {
    # Cut power to the modem for ten seconds.
    echo "1" > /sys/class/gpio/gpio18/value
    sleep 10
    echo "0" > /sys/class/gpio/gpio18/value
}

init_gpio
reset_modem
