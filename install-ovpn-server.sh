#!/bin/bash
clear

echo "
  ____               __      _______  _   _      _____           _        _ _           
  / __ \              \ \    / /  __ \| \ | |    |_   _|         | |      | | |          
 | |  | |_ __   ___ _ _\ \  / /| |__) |  \| |______| |  _ __  ___| |_ __ _| | | ___ _ __ 
 | |  | | '_ \ / _ \ '_ \ \/ / |  ___/| . ' |______| | | '_ \/ __| __/ _' | | |/ _ \ '__|
 | |__| | |_) |  __/ | | \  /  | |    | |\  |     _| |_| | | \__ \ || (_| | | |  __/ |   
  \____/| .__/ \___|_| |_|\/   |_|    |_| \_|    |_____|_| |_|___/\__\__,_|_|_|\___|_|   
        | |                                                                              
        |_|                                                                              

###############################################################################
## www.github.com/DylanAKing/OpenVPN-Installer/install-ovpn-server.sh        ##
##                                                                           ##
## Script Author: Dylan A King                                               ##
## Script Version: 1.0.3                                                     ##
## Version Date: 11/26/2020                                                  ##
###############################################################################
# This script runs commands on 2 systems and assumes you have a second system #
# or VM to be used as a CA, and during the installation you will be asked to  #
# provide login credentials and ipv4 address of the second system, then this  #
# script will automatically configure the second system over SSH              #
###############################################################################

INFO: Starting Server configuration...
Please enter the username of your non-root user:
"
read usrname

echo '
SERVER INFO: Updating Sever system and installing dependencies...
'

##update host
sudo apt update && sudo apt upgrade ssh openvpn easy-rsa ufw -y

echo '
SERVER INFO: Configuring Firewall...
'

##allow Openssh through the firewall if installed
sudo ufw allow openssh

##allow default port 1194/UDP through the firewall
sudo ufw allow 1194/udp

##allow port 80 through the firewall
#sudo ufw allow 80

##allow port 443/tcp through the firewall
#sudo ufw allow 443/tcp

echo '
SERVER INFO: Generating the Server SSH-Key...
'

##generate a strong 4096-bit ssh-key to be sent to the CA
ssh-keygen -b 4096

echo '
SERVER INFO: Setting up Easy-RSA directory structure...
'

##make root directory for easy-rsa
mkdir ~/easy-rsa

##create a synthetic link from '/usr/share/easy-rsa' to '~/easy-rsa'
ln -s /usr/share/easy-rsa/* ~/easy-rsa

##change ownership of ~/easy-rsa directory to the non-root user
sudo chown "$usrname" ~/easy-rsa

##change permissions on the ~/easy-rsa directory
chmod 700 ~/easy-rsa

##change to the '~/easy-rsa' directory
cd ~/easy-rsa

echo '
SERVER INFO: Creating the Servers vars file...
'

##create the 'vars' file for the server
cat > /tmp/vars << EOF
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF

#move the newly created vars file to the correct location
mv /tmp/vars ~/easy-rsa/

echo '
SERVER INFO: Initializing Public Key Infrastructure...
'

##initialize the pki
./easyrsa init-pki

echo '
INFO: Finished initial configuration of the server system.
'

###############################################################

###############################################################
##this section will configure the OpenVPN Certificate Authority
##by connecting to a second ubuntu 20.04 system via SSH

echo '
INFO: Starting Certificate Authority configuration...
'

echo '
Please enter the username for the second system or VM:
'
read name

#display the current ip information for all interfaces
ip a

echo For convenience above is the IP information for the Server system.

echo '
Please enter the ipv4 address of the first system/Server system:
'
read ipv4

echo '
Please enter the ipv4 address of the second system/Certificate Authority system:
'
read ipv4ca

##here we use ssh-copy-id to securely transfer the ssh-key we generated
##earlier this enables heightened security when logging in with ssh
##because you do not have to type a password to authenticate,
##however, for this to be most effective password-based authentication
##should be disabled on the systems using ssh-key based authentication.
##disabling password-based authentication should prevent malicious 
##actors from successfully brute-forcing the user's password. 
##this script leaves password-based auth. enabled as a fail-safe.

echo '
SERVER INFO: Transferring the Servers SSH-Key to the Certificate Authority...
'

##transfer the server's ssh-key to the CA
ssh-copy-id "$name"@"$ipv4ca"

echo '
CA INFO: Generating the Certificate Authority SSH-Key...
'

##generate a strong 4096 bit
ssh "$name"@"$ipv4ca" ssh-keygen -b 4096

echo '
CA INFO: Transferring Certificate Authority SSH-Key to the Server...
'

##transfer the CA's ssh-key to the Server
ssh "$name"@"$ipv4ca" ssh-copy-id "$usrname"@"$ipv4"

echo '
CA INFO: Updating Certificate Authority and installing dependencies...
'

##update the remote system and install Easy-RSA
ssh -t "$name"@"$ipv4ca" 'sudo apt update; sudo apt upgrade easy-rsa ufw -y'

echo '
CA INFO: Setting up '~/easy-rsa' directory...
'

##make the '~/easy-rsa' directory
ssh "$name"@"$ipv4ca" mkdir ~/easy-rsa

##create a synthetic link from '/usr/share/easy-rsa/ to ~/easy-rsa/
ssh "$name"@"$ipv4ca" ln -s /usr/share/easy-rsa/* ~/easy-rsa

##change permissions of the '~/easy-rsa' directory
ssh "$name"@"$ipv4ca" chmod 700 ~/easy-rsa

echo '
CA INFO: Initializing Certificate Authority Public Key Infrastructure...
'

##change to the '~/easy-rsa' directory and create the pki infrastructure
ssh "$name"@"$ipv4ca" 'cd ~/easy-rsa; ./easyrsa init-pki'

##this section creates a file called 'vars' in the '~/easy-rsa' directory
##and places the lines below into the file using a method known
##as 'here documents'. Set the values in quotations("") to whatever you 
##want just do not leave them blank.

echo '
CA INFO: Creating Certificate Authority vars file...
'

ssh "$name"@"$ipv4ca" cat > ~/easy-rsa/vars << EOF
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "NewYork"
set_var EASYRSA_REQ_CITY       "New York City"
set_var EASYRSA_REQ_ORG        "Copyleft Foundation"
set_var EASYRSA_REQ_EMAIL      "admin@example.com"
set_var EASYRSA_REQ_OU         "Community"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
EOF

echo '
CA INFO: Building Easy-RSA Certificate Authority
'

##build the Certificate Authority on the remote system 
ssh "$name"@"$ipv4ca" 'cd ~/easy-rsa; ./easyrsa build-ca nopass'

echo '
INFO: Finished configuration of Certificate Authority...
'

#############################################################

###########################################################################
##this section will finish setting up the OpenVPN Server and associating it
##with the configured CA server

echo '
SERVER INFO: Generating Server Public Key and Certificate Request...
'

##change to the '~/easy-rsa' directory
cd ~/easy-rsa

##generate the server`s request and key
./easyrsa gen-req server nopass

echo '
SERVER INFO: Copying Server Public Key to '/etc/openvpn/server/'...
'

##copy server key to the '/etc/openvpn/server' directory 
sudo cp ~/easy-rsa/pki/private/server.key /etc/openvpn/server/

echo '
SERVER INFO: Transferring the Servers Request to the Certificate Authority...
'

##send the server.req file to the Certificate Authority for signing
scp ~/easy-rsa/pki/reqs/server.req "$name"@"$ipv4ca":/tmp/

echo '
CA INFO: Importing and Signing the Servers Request...
'

##connect to the CA via SSH, import and sign the request
ssh "$name"@"$ipv4ca" 'cd ~/easy-rsa; ./easyrsa import-req /tmp/server.req server; ./easyrsa sign-req server server'

echo '
CA INFO: Moving signed Certificates to the /tmp directory...
'

##connect to the CA via SSH and copy the new server certificate to the /tmp/ directory
ssh "$name"@"$ipv4ca" cp ~/easy-rsa/pki/issued/server.crt /tmp/
 
##connect to the CA via SSH and copy the CA certificate to the /tmp directory
ssh "$name"@"$ipv4ca" cp ~/easy-rsa/pki/ca.crt /tmp/

echo '
SERVER INFO: Retreiving the signed Certificates from the Certificate Authority...
'

##using SCP to retrieve the Server Certificate and CA Certificate from the CAs /tmp directory 
scp "$name"@"$ipv4ca":/tmp/*.crt /tmp/

##copy the server and CA certificates and place them in the '/etc/openvpn/server' directory
sudo cp /tmp/{server.crt,ca.crt} /etc/openvpn/server/

##make the '/client-configs' directory and the 'client-configs/keys' sub-directory
mkdir -p ~/client-configs/keys

##Change the permissions of the '~/client-configs' directory
sudo chmod -R 700 ~/client-configs

##copy the CA certificate and place it in the '~/client-configs/keys/' directory
sudo cp /etc/openvpn/server/ca.crt ~/client-configs/keys

echo '
SERVER INFO: Generating TLS-Crypt Pre-Shared Key...
'

#move to `/easy-rsa' directory
cd ~/easy-rsa

##generate the tls-crypt pre-shared key
sudo openvpn --genkey --secret ta.key

##copy the pre-shared key to the '/etc/openvpn/server' directory
sudo cp ta.key /etc/openvpn/server/

#copy ta.key to '~/client-configs/keys' directory
sudo mv ta.key ~/client-configs/keys/

##Change ownership of the ca.crt and ta.key to the nonroot user
sudo chown -R "$usrname" ~/client-configs/keys/

##copy a sample server.conf file to the /etc/openvpn/server/ directory
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/server/

##the current state of this script uses a file that is stripped of all 
##unused configuration options and comments for each directive, please
##refer to ~/example-server.conf for more information on the directives
##that are in use and available. A zipped copy of server.conf is stored
##in /etc/openvpn/server, that is the correct directory for the unzipped
##server.conf when its ready to be used.

##copy the example server.conf to the home directory
sudo cp /etc/openvpn/server/server.conf.gz ~/

##unzip the example server.conf in the
sudo gunzip ~/server.conf.gz

##rename server.conf to example-server.conf
mv ~/server.conf ~/example-server.conf

echo '
SERVER INFO: Creating Server Configuration file...
'

##create the trimmed server.conf that will be used by the server
##this server.conf only contains the active directives indicated
##on the following lines
###

sudo cat > /tmp/server.conf << EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh none
topology subnet
server 10.8.0.0/24 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
client-to-client
keepalive 10 120
tls-crypt ta.key
cipher AES-256-GCM
auth sha256
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

###
##move the new server.conf file from '/tmp' to '/etc/openvpn'
sudo mv /tmp/server.conf /etc/openvpn/server/

echo '
SERVER INFO: Adjusting IP-Fowarding Policy...
'

##append the following line to '/etc/sysctl.conf' adjusting the ip fowarding policy
echo "net.ipv4.ip_forward = 1"|sudo tee -a /etc/sysctl.conf

echo '
SERVER INFO: Applying updated IP-Fowarding Policy to the current session...
'

##load the new ip forwaing values for the current session
sudo sysctl -p

echo '
SERVER INFO: Backing up ufw/before.rules before modification

SERVER INFO: Backup saved at: /etc/ufw/before.rules.bak
'

##create a copy of "before.rules" in the same directory as a backup
sudo cp /etc/ufw/before.rules /etc/ufw/before.rules.bak

echo '
Please enter the name of the Server network interface you want to use:
'
read if

echo '
SERVER INFO: Creating temporary file to hold new rules...
'

##add new rules to a temporary file that will be joined with /etc/ufe/before.rules using cat
sudo cat > /tmp/temp.txt << EOF 
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/8 -o "$if" -j MASQUERADE
COMMIT
EOF

echo '
SERVER INFO: Adding new rules to '/etc/ufw/before.rules'...
'

##use cat to join the before.rules to the temperary file containing the new rules
##this results in the contents of the first file appearing at the start of the second
sudo cat /tmp/temp.txt /etc/ufw/before.rules.bak >> /tmp/before.rules

##move new file to the correct location
sudo mv /tmp/before.rules /etc/ufw/

##restore the appropriate permissions for /etc/ufw/before.rules
sudo chmod 640 /etc/ufw/before.rules

echo '
SERVER INFO: Backing up /etc/default/ufw before modification...

SERVER INFO: Backup stored at: /etc/default/ufw.bak
'

##backup /etc/default/ufw
sudo cp /etc/default/ufw /etc/default/ufw.bak

echo '
SERVER INFO: Editing '/etc/default/ufw'...
'

##create the new file in the /tmp directory
sudo cat > /tmp/ufw << EOF
IPV6=yes
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="ACCEPT"
DEFAULT_APPLICATION_POLICY="SKIP"
MANAGE_BUILTINS=no
IPT_SYSCTL=/etc/ufw/sysctl.conf
IPT_MODULES=""
EOF

##move the new file to the correct location
sudo mv /tmp/ufw /etc/default/

##restore the appropriate permissions for /etc/default/ufw
sudo chmod 644 /etc/default/ufw

##make '~/client-configs/files' directory
mkdir ~/client-configs/files

##backup the normal base.conf, a trimmed base.conf will be used by this script
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/example-base.conf

echo '
SERVER INFO: Create the client base configuration...
'

##create the trimmed base.conf in '~/client-configs/'
sudo cat > ~/client-configs/base.conf << EOF
client
dev tun
proto udp
remote $ipv4 1194
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

echo '
SERVER INFO: Enabling Firewall...
'

##enable firewall on startup
sudo ufw enable

echo '
SERVER INFO: Starting OpenVPN Server...
'

#start OpenVPN Server
sudo systemctl start openvpn-server@server.service

##uncomment to enable OpenVPN to run on startup
#sudo systemctl enable openvpn-server@server.service

echo '
SERVER INFO: Making Management scripts Executable...
'

#make the managment scripts executable
chmod +x ~/OpenVPN-Installer*/OpenVPN-Management-Scripts/*.sh

#transfer the signreq.sh script to the CA
scp ~/OpenVPN-Installer*/OpenVPN-Management-Scripts/signreq.sh "$name"@"$ipv4ca":/tmp/

# move the signreq.sh script on the CA from /tmp to ~/
ssh "$name"@"$ipv4ca" mv /tmp/signreq.sh ~/

echo '
INFO: The installation is now complete!

To start the server;
run: systemctl start openvpn-server@server.service

To enable the server to run on startup;
run: systemctl enable openvpn-server@server.service

To check Openvpn-server status;
run: systemctl status openvpn-server@server.service

Remeber to shutdown the Certificate Authority when its not actively
being used to sign certificates for added security 
to do this remotely run: ssh '"$name"'@'"$ipv4ca"' shutdown now

INFO: Checking Openvpn-server@server.service status...

INFO: Press "q" to quit'

#display the status of the OpenVPN server
systemctl status openvpn-server@server.service

## Sources:
################################################################################################################
##this script was derived from two tutorials by Jamon Camisso.
##below are links to the tutorials:
##
##OpenVPN Server Configuration:
##Source published on: 5/6/2020
##https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04
##
##OpenVPN/EASY-RSA Certificate Authority configuration:
##Source published on 4/28/2020
##https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04+
#######################################################################
##Disclaimer!!!##
##This installer script is not affiliated with OpenVPN® or OpenVPN Inc.
##
##© 2002-2019 OpenVPN Inc.
##OpenVPN is a registered trademark of OpenVPN Inc.
#######################################################################
