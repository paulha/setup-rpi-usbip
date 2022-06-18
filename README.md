# setup-rpi-usbip
Files to set up usbip server on Raspberry Pi

## Source Articles:

- https://developer.ridgerun.com/wiki/index.php?title=How_to_setup_and_use_USB/IP
- https://derushadigital.com/other%20projects/2019/02/19/RPi-USBIP-ZWave.html

## Server Process
SSH to raspbian and execute the following commands:

sudo -s
lsusb
lsusb should show a list of attached USB devices, here’s what mine looks like:

Bus 001 Device 006: ID 10c4:8a2a Cygnal Integrated Products, Inc.
Bus 001 Device 005: ID 0557:2306 ATEN International Co., Ltd
Bus 001 Device 004: ID 0781:5583 SanDisk Corp.
Bus 001 Device 003: ID 0424:ec00 Standard Microsystems Corp. SMSC9512/9514 Fast Ethernet Adapter
Bus 001 Device 002: ID 0424:9514 Standard Microsystems Corp.
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
We’re looking for the device identifier for the USB radio, which in my case is that Cygnal Integrated Products, Inc. device with an ID of 10c4:8a2a. We’ll then setup a systemd service definition that is going to search for that device string and attach it to the USBIPd service. If you’re using a different USB device, change the device ID in the lines below for ExecStartPost and ExecStop

# Install usbip and setup the kernel module to load at startup
apt-get install usbip
modprobe usbip_host
echo 'usbip_host' >> /etc/modules

# Create a systemd service
vi /lib/systemd/system/usbipd.service
Copy and paste the following service definition:

```
[Unit]
Description=usbip host daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/usbipd -D
ExecStartPost=/bin/sh -c "/usr/sbin/usbip bind --$(/usr/sbin/usbip list -p -l | grep '#usbid=10c4:8a2a#' | cut '-d#' -f1)"
ExecStop=/bin/sh -c "/usr/sbin/usbip unbind --$(/usr/sbin/usbip list -p -l | grep '#usbid=10c4:8a2a#' | cut '-d#' -f1); killall usbipd"

[Install]
WantedBy=multi-user.target
```
Save that file, then run the following commands in your shell:

# reload systemd, enable, then start the service
```
sudo systemctl --system daemon-reload
sudo systemctl enable usbipd.service
sudo systemctl start usbipd.service
```
## Setting up the USB/IP client (on Linux!)
### Client Requirements
Linux server/desktop (Tested on Ubuntu server 17.04. There are some Windows builds but I couldn’t get any of them to work reliably under Win10/Server 2016)
IP address of your RPi running as a server. Here I’m using 192.168.0.10.
Client Process
SSH to the Linux server and execute the following commands:
```
sudo -s
apt-get install linux-tools-generic -y
modprobe vhci-hcd
echo 'vhci-hcd' >> /etc/modules
```
Much like we did on the server, we’re going to need to modify the ExecStart and ExecStop lines below to search for the correct USB device ID that’s being presented by your USB/IP server. Likewise, change the IP 192.168.0.10 to match your RPi USB server.

vi /lib/systemd/system/usbip.service
Copy and paste the following service definition:

```
[Unit]
Description=usbip client
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c "/usr/lib/linux-tools/$(uname -r)/usbip attach -r 192.168.0.10 -b $(/usr/lib/linux-tools/$(uname -r)/usbip list -r 192.168.0.10 | grep '10c4:8a2a' | cut -d: -f1)"
ExecStop=/bin/sh -c "/usr/lib/linux-tools/$(uname -r)/usbip detach --port=$(/usr/lib/linux-tools/$(uname -r)/usbip port | grep '<Port in Use>' | sed -E 's/^Port ([0-9][0-9]).*/\1/')"

[Install]
WantedBy=multi-user.target
```

Save that file, then run the following commands in your shell:

# reload systemd, enable, then start the service
sudo systemctl --system daemon-reload
sudo systemctl enable usbip.service
sudo systemctl start usbip.service
You should now be able to access the USB device over the network as if the device was plugged in locally, and you have an auto-starting systemd service to control things.)

