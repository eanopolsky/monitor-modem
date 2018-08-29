install:
	cp monitor-modem.sh /usr/local/sbin/
	cp monitor-modem.service /lib/systemd/system/
	systemctl daemon-reload
	systemctl start monitor-modem
	systemctl enable monitor-modem

