# OpenVPN-Installer
Single script configuration of two clean ubuntu servers 1x ovpn server and 1x ovpn/easyrsa certificate authority

##Disclaimer!!!##\
This installer script is not affiliated with OpenVPN® or OpenVPN Inc.\
\
© 2002-2019 OpenVPN Inc.\
OpenVPN is a registered trademark of OpenVPN  Inc.\
#################

The goal of this script is to create a simple installation method to install and configure two clean ubuntu servers

this readme has sourced at the bottom, two tutorials that the install script is based off of, please refer to those
for more details on the rationale behind some of these commands, or if you encouter any issues while running the 
install script. through out the installation the script will echo 'info flags' to help you determine the stage of 
the script, these should aid in where in the script you started encountering issues for easier troubleshooting.

an example an 'info flag':
##
"INFO: Create the client base configuration..."
##
the end result of running the install script is a functional OpenVPN server ready to add clients, and issue .ovpn profiles,
it does require additional networking configuration to allow for access from outside of the LAN.

the install script creates some stripped down versions of a couple of files (removing all unused configuration options and 
comments), one of them being '/etc/default/ufw'.

(while I dont like this approach for editing system files, it was the first solution I thought of that worked,
if you see this and have an alternative, perhaps not as invasive solution, please let me know.)

  /etc/openvpn/server/server.conf and ~/client-configs/base.conf are two other files that use this method, please refer
to ~/example-base.conf, and ~/example-server.conf for additonal configuration options and to understand the 
directives in the stripped down versions.

the install script sets up the client config files with only one remote server with a local address so to enable access from 
outside of the LAN you need to add additional remote servers to the configuration file, this can be done with either
a public facing ip address or a Fully Qualified Domain Name(FQDN). you can do this by editing the script before you
run it and add additional 'remote ipaddress/FQDN port' lines as shown below:
#####################################################
echo INFO: Create the client base configuration...

##create the trimmed base.conf in '~/client-configs/'
#sudo cat > ~/client-configs/base.conf << EOF\
client\
dev tun\
proto udp\
remote $ipv4 1194 < this line uses the ip address in variable $ipv4 provided during the script and add it as the first default remote server\
remote ipaddress/FQDN port\
^ add new lines here replacing the above 'ipaddress/FQDN' and 'port' with the correct info for you.(ex: remote 0.0.0.0 1194; remote www.example.com 1194)\
resolve-retry infinite\
user nobody\
group nobody\
persist-key\
persist-tun\
remote-cert-tls server\
cipher AES-256-GCM\
auth sha256\
key-direction 1\
verb 3\
EOF\
######################################################

After you add new remote server addresses you still will need to port foward the ports chosen during the install
the default values for the script require port 1194 be forwarded to the OpenVPN Server System

Installation requirements:\
  -2 clean ubuntu 20.04 systems or Virtual machines with lan access\
  -ip addresses of both systems\
  -active internet connection
  
Installation instructions:\
 1.) download a zipped copy of the repo, and unzip it\
 2.) if you havent look over the README.md\
 3.) run ./install-ovpn-server.sh and follow the prompts

SOURCES:
  this script was derived from two tutorials by Jamon Camisso.
below are links to the tutorials:

OpenVPN Server Configuration:\
Source published on: 5/6/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04

OpenVPN/EASY-RSA configuration:\
Source published on 4/28/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04+
