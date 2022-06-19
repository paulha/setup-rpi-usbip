#!/usr/bin/env bash

which usbip || sudo apt-get install usbip
sudo modprobe usbip_host
(cat /etc/modules | grep -v "usbip_host") && sudo chmod og+w /etc/modules && sudo echo 'usbip_host' >>/etc/modules && sudo chmod og-w /etc/modules
sudo cp usbipd.service /lib/systemd/system/usbipd.service
sudo systemctl --system daemon-reload
sudo systemctl enable usbipd.service
sudo systemctl start usbipd.service
usbip list -r localhost
