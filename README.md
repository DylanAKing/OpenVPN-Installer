# OpenVPN-Installer
| Latest Release | 1.0.3 |
| -------------- | ----- |

Single script configuration of two clean servers/VMs into 1x OVPN server and 1x OVPN/EasyRSA certificate authority

The end result of running the install script is a functional OpenVPN server ready to add clients, and issue .ovpn profiles,
as well as accept connections, however it does require additional configuration to allow for access from outside of the LAN.

CLONING FROM MAIN MAY INTRODUCE SOME BUGS THAT HAVENT BEEN ADDRESSED YET PLEASE USE THE LASTEST VERSION FROM RELEASES
FOR A TESTED VERSION

# Linux Distro Compatibility:
| Distro          |  Version  |     Supported?     |
| --------------- | --------- | ------------------ |
|     Ubuntu      |  20.04+   | :white_check_mark: |
|     Debian      |  10.6.0+  | :white_check_mark: |
| Raspberry Pi OS | 8.20.2020 | :white_check_mark: |
|       Arch      |  Rolling  |      Planned       |
|      Gentoo     | --------- |      Planned       |
|      Fedora     |    33+    |      Planned       |


# Disclaimer
This installer script is not affiliated with OpenVPN® or OpenVPN Inc.

© 2002-2019 OpenVPN Inc.\
OpenVPN is a registered trademark of OpenVPN  Inc.

# Installation Requirements:
Basic Requirements

    - 2 clean Server Systems or Virtual Machines with lan access
    
    - LAN ip addresses of both systems
      
    - Identity of the network interface to use on the Server System(ex: en0, eth0, ens18,...) 

Script Dependencies:

    - EasyRSA v3.0.0 or higher (script was built using v3.0.6, but should be backward compatible to atleast v3.0.0)
    
    - Sudo
    
    - ufw

# Installation Instructions:

For the installation script to function we need to have SSH running on each system to check if its enabled run:

    systemctl status ssh

If you need to start it run:

    sudo systemctl start ssh
    
If you want ssh to run on start up:

    sudo systemctl enable ssh

If you are running Debian 10.6.0 there are a few things to verify before you run the installer

Make sure you have these packages installed:

        - sudo
    
        - ufw
    
        - unzip (or select an alternative dependant on your download format ex: .zip, .tar.gz)
    
Verify the Desired non-root user is in the sudoers file '/etc/sudoers'\
the way i know to do this is by adding the following line to '/etc/sudoers'
    
        $username ALL=(ALL:ALL) ALL
      
Replacing $username with the name on your non root user and placing this line\
below the corresponding line for ROOT. \
Please inform me if there is a better way to acheive this.
  
With these packages installed and a non-root user capable of using the "sudo" command,
you are ready to run the installer, just follow the ubuntu instructions below.

If your running ubuntu 20.04, or completed the steps outlined aboved:

    - From your home directory, Clone this Repository and Extract it
  
    - Make the install script executable with:  chmod +x ~/OpenVPN-Installer-*/install-ovpn-server.sh
  
    - Start the installation with:  ./install-ovpn-server.sh

Through out the installation, the script will echo 'INFO:' flags to help you determine the stage of 
the script and where in the script you started encountering issues for easier troubleshooting. These flags always
precede the process they reference. so if an issue occurs during the "SERVER INFO: Configuring Firewall..." for
example you should find that spot in the script to understand what was happening when the error occured.

Example 'INFO:' flags:

    - "SERVER INFO: ..." < shows the script is executing commands on the host OpenVPN Server system
    
    
    - "CA INFO: ..." < shows the script is executing commands on the remote OpenVPN Certificate Authority system
   
The install script creates some stripped down versions of a couple of files (removing all unused configuration options and 
comments), one of them being '/etc/default/ufw'.

(note: while I dont like this approach for editing system files, it was the first solution I thought of that worked,
if you see this and have an alternative, perhaps less invasive solution, please let me know.)

/etc/openvpn/server/server.conf and ~/client-configs/base.conf are two other files that use this method, please refer
to ~/example-base.conf, and ~/example-server.conf for additonal configuration options and to understand the 
directives in the stripped down versions.

The install script sets up the client config files with only one remote server with a local address so to enable access from 
outside of the LAN you need to add additional remote servers to the configuration file, this can be done with either
a public facing ip address or a Fully Qualified Domain Name(FQDN). you can do this by editing the script before you
run it and add additional 'remote IP/FQDN port' lines as shown below (plans to release a script to handle this):

    ##create the trimmed base.conf in '~/client-configs/'
    sudo cat > ~/client-configs/base.conf << EOF
    client
    dev tun
    proto udp
    remote $ipv4 1194 < this line uses the IP stored in $ipv4, and adds it as the first server on port 1194
    remote IP/FQDN port
    ^ add new lines here replacing the 'IP/FQDN' & 'port'.(ex: remote 0.0.0.0 1194; remote www.example.com 1194)
    resolve-retry infinite
    user nobody
    group nobody
    persist-key
    persist-tun
    remote-cert-tls server
    cipher AES-256-GCM
    auth sha256
    key-direction 1
    verb 3
    EOF

After you add new remote server addresses you still will need to foward the ports on your router.

The default values for the install script require port 1194 be forwarded to the OpenVPN Server System.

# SOURCES

This script was derived from two tutorials by Jamon Camisso.\
below are links to the tutorials:

OpenVPN Server Configuration:\
Source published on: 5/6/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04

OpenVPN/EASY-RSA configuration:\
Source published on 4/28/2020\
https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04+
