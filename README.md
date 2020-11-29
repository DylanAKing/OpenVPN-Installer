# OpenVPN-Installer
Single script configuration of two clean servers/VMs into 1x OVPN server and 1x OVPN/EasyRSA certificate authority

Linux Distro Compatibility:

| Latest Version | 1.0.3 |
| -------------- | ----- |

| Distro | Version |     Supported?     |
| ------ | ------- | ------------------ |
| Ubuntu |  20.04  | :white_check_mark: |
|        | < 18.04 | :x:                |
| Debian |  10.6.0 | :white_check_mark: |
|  Arch  | Rolling |      Postponed     |

##Disclaimer!!!##\
This installer script is not affiliated with OpenVPN® or OpenVPN Inc.\

© 2002-2019 OpenVPN Inc.\
OpenVPN is a registered trademark of OpenVPN  Inc.\

Installation instructions
If you are running Debian 10.6.0 there are a few things that you need to verify before you begin the installtion

    - Make sure you have these packages installed:

        - sudo
    
        - ufw
    
        - unzip ((optional)or select an alternative dependant on your download format ex: .zip, .tar.gz)
    
    - Verify the Desired non-root user is in the sudoers file '/etc/sudoers'\
    the way i know to do this is by adding the following line to '/etc/sudoers'
    
        $username ALL=(ALL:ALL) ALL
      
    replacing $username with the name on the non root user and placing this line below the corresponding line for ROOT\
    Please inform me if there is a better way to acheive this.
  
    - With these packages installed and a non-root user capable of using the "sudo" command, youre ready to install
    just follow the ubuntu instructions below

If your running ubuntu 20.04, or completed the steps outlined aboved:

    - Clone this Repository and Extract it
  
    - Make the install script executable with:  chmod +x ../install-ovpn-server.sh
  
    - Start the installation with:  ./install-ovpn-server.sh
 
this readme has sourced at the bottom, two tutorials that the install script is based off of, please refer to those
for more details on the rationale behind some of these commands, or if you encouter any issues while running the 
install script. through out the installation, the script will echo 'INFO:' flags to help you determine the stage of 
the script and where in the script you started encountering issues for easier troubleshooting. These flags always
precede the process they reference. so if an issue occurs during the "SERVER INFO: Configuring Firewall..." for
example you should find that spot in the script to understand what was happening when the error occured.

Example 'INFO:' flags:

    - "SERVER INFO: (some Text)" < shows that the script is executing commands on the host OpenVPN Server system
    
    
    - "CA INFO: (some text)" < shows that the script is executing commands on the remote OpenVPN Certificate Authority system
   
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
run it and add additional 'remote IP/FQDN port' lines as shown below:

echo INFO: Create the client base configuration...

##create the trimmed base.conf in '~/client-configs/'
#sudo cat > ~/client-configs/base.conf << EOF\
client\
dev tun\
proto udp\
remote $ipv4 1194 < this line uses the IP stored in $ipv4, and adds it as the first default remote server on port 1194\
remote IP/FQDN port\
^ add new lines above replacing the 'IP/FQDN' & 'port' with your info.(ex: remote 0.0.0.0 1194; remote www.example.com 1194)\
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
EOF

After you add new remote server addresses you still will need to port foward the ports chosen during the install
the default values for the script require port 1194 be forwarded to the OpenVPN Server System

Installation requirements:

    - 2 clean Server systems or Virtual machines with lan access
    
    - ip addresses of both systems
    
    - active internet connection on one system and lan acess to the other
    
    - identity of the network interface to use on the Server(ex: en0, eth0, ens18,...)

Package Dependencies:

    - EasyRSA v3.0.0 or higher (script was built using v3.0.6, but should be backward compatible)
    
    - Sudo
    
    - ufw
  
SOURCES:\
this script was derived from two tutorials by Jamon Camisso.\
below are links to the tutorials:

OpenVPN Server Configuration:\
Source published on: 5/6/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04

OpenVPN/EASY-RSA configuration:\
Source published on 4/28/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04+
