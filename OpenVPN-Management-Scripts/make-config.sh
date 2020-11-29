#!/bin/bash
########################################################################
##this script will take the sign client certificate and other required##
##keys and create the actual .ovpn profile that will be used by the   ##
##client to connect to the VPN                                        ##
########################################################################

#take the name of the client from the user
echo Please enter the common-name of the client:
read name

#move the signed certificate to the keys directory
mv /tmp/"$name".crt ~/client-configs/keys

########################################################################
#this section of code is borrowed from the tutorial on configuring the #
#OpenVPN Server, please refer to the README.md for a hyperlink to the  #
#afformentioned tutorial, there is one modification from the original  # 
#that removes the arguement from the scripts call command replacing it #
#with a prompt for call consistency between this script and other      #
#custom scripts for managing OpenVPN that were packaged with           #
#DylanAKing/OVPN-Installer                                             #

#declaring filesystem paths as easily called variables
KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf

#this section echos the contents of the required key files into a copy
#of the ~/client-configs/base.conf creating a .ovpn profile containing
#the necessary keys required to connect to the VPN
cat "${BASE_CONFIG}" \
    <(echo -e '<ca>') \
    "${KEY_DIR}"/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    "${KEY_DIR}"/"$name".crt \
    <(echo -e '</cert>\n<key>') \
    "${KEY_DIR}"/"$name".key \
    <(echo -e '</key>\n<tls-crypt>') \
    "${KEY_DIR}"/ta.key \
    <(echo -e '</tls-crypt>') \
    > "${OUTPUT_DIR}"/"$name".ovpn
########################################################################

echo '
Your OVPN Profile is stored at:
~/client-configs/files/'"$name"'.ovpn'
