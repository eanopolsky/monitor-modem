install:
	cp monitor-modem.sh /usr/local/sbin/
	chown root:root /usr/local/sbin/monitor-modem.sh
	chmod 755 /usr/local/sbin/monitor-modem.sh
	cp monitor-modem.service /lib/systemd/system/
	chown root:root /lib/systemd/system/monitor-modem.service
	chmod 644 /lib/systemd/system/monitor-modem.service
	cp monitor-modem.cfg /usr/local/etc/
	chown root:root /usr/local/etc/monitor-modem.cfg
	chmod 644 /usr/local/etc/monitor-modem.cfg
	systemctl daemon-reload
	systemctl restart monitor-modem
	systemctl enable monitor-modem

uninstall:
	systemctl stop monitor-modem
	systemctl disable monitor-modem
	rm /usr/local/sbin/monitor-modem.sh
	rm /lib/systemd/system/monitor-modem.service
	# Leave the config file behind in case the user wants to reinstall.
	# rm /usr/local/etc/monitor-modem.cfg
