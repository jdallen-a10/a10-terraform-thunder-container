# a10-terraform-thunder-container
Terraform files to run Thunder Container on Docker

This is a demo environment that makes use of a Ubuntu VM running on a VirtualBox hypervisor. This allows for
demo's to be run on a laptop environment!  The Terraform files are located in a directory on the host computer,
and point to the VM's IP address.  Docker-ce is installed on the Ubuntu VM.  You can use other Linux OS for 
your guest VM...I used Ubuntu 16.04 LTS for my demo VM.  There are several files that need to be moved onto
the Docker VM. I put them in a '/root/terraform/basic-sl' directory. These are referenced in the Terrform files...
be sure to change those lines in the Terraform files to reflect your environment.

The 'startDemo.sh' and 'stopDemo.sh' automate the starting and stopping of the 'Basic SLB' demo. The 'startDemo.sh'
script will only work on a Mac OSX machine. If you come up with an Windows start/stop, please feel free to do
a pull request!

There is a Syslog server that I use to show log messages from the cThunder. I use my own version, but any
syslog server should work just fine. My Syslog server is located here: https://github.com/jdallen-a10/syslog-ng

NOTE!   Terraform does NOT seem to be able to (Sept. 2020 -- version ) attach a port to a specific network.
Because of this, you will NOT be able to bring up the webpage from outside of the VM.  You will have to use
something like curl to connect to the 'slb-outside-net' interface on the cThunder in order to show the
connection to one of the Nginx containers, or use a reverse proxy from the default 'bridge' network to the 
cThunder SLB port.
