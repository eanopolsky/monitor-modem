# Description

monitor-modem detects when an Internet connection has gone out and reboots the
modem. It is designed to run on a Raspberry Pi 3 model B+, but may work on
other Pi models.

WARNING: High voltage is dangerous. Do not attempt to work with high voltage
if you lack sufficient training in electrical safety or feel even slightly
uncomfortable about the prospect of working with high voltage. If you make a
mistake, you could be injured or killed.

# Installation

1. Get a Raspberry Pi 3 model B+. If you are a Raspberry Pi expert, you may
wish to use a different model.

2. Download and install the raspbian desktop image from https://www.raspberrypi.org/downloads/raspberry-pi-desktop/

3. Build or buy a relay capable of controlling the power supply to your modem.

4. Connect the relay to the Raspberry Pi GPIO header according to the relay
instructions. Typically this will involve connecting one terminal on the relay
to a ground pin on the GPIO header and another terminal on the relay to a
regular 3.3V GPIO pin. The relay should be wired so that when the GPIO pin is
at 0V relative to ground, power should be applied to the modem, but when the
GPIO pin is at +3.3V relative to ground, power to the modem should be
interrupted.

5. If you have the most common kind of modem, one that contains an integrated
ethernet switch and is configured to provide a private IP address to connected
devices via DHCP, connect an ethernet cable between the modem and the Pi. If
you have a different kind of modem, you may need to connect or configure the
Pi differently so that it has Internet access. This is left as an exercise to
the reader.

6. Clone this project to your Pi.

7. Copy monitor-modem.cfg.example to monitor-modem.cfg, and change the RELAYPIN
variable to the GPIO pin you chose in step 4. Use the BCM pin number from this
graphic: https://pinout.xyz/ For example, if the relay is wired to the pin in
the lower right corner of the image, use RELAYPIN="21", **not** RELAYPIN="40".

8. (Optional) Customize the HOSTS variable to suit your tastes. The default
will be fine for most people.

9. From the project directory, run sudo make install.

That's it!

# FAQ

Q: What happens if the Pi loses power?

A: The modem will stay on, provided it has a good, independent power source.
If the Pi loses power, the GPIO pin controlling the relay will stay at 0V. In
this condition, the C and NC terminals on the relay will be connected, and
power will flow to the modem.

Cutting power to a Pi without first shutting down gracefully does sometimes
cause SD card corruption. You can mitigate this by booting from a USB flash
drive (https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md)
or using a UPS. If the Pi does suffer SD card corruption and fails to boot
properly after power is restored, the GPIO pin controlling the relay will stay
at 0V and power to the modem will stay on.

# Development

This project has no dependencies beyond what comes preinstalled with the
Raspberry Pi desktop.

If you wish to contribute, please send a pull request.

# License

This project is licensed under the GPLv3 or, at your option, any later version.
