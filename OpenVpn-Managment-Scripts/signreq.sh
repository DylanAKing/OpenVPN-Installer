#!/bin/bash
#########################################################################
##this script will import and sign a certificate request that is stored##
##in the /tmp directory, and send it back to the OpenVPN Server's /tmp ##
##directory.                                                           ##
##this script is meant to be run locally on the Certificate Authority  ##
#########################################################################

#change to the easy-rsa directory 
cd ~/easy-rsa

#ask for the common name of the client
echo Please enter the common-name of the client:
read name

#ask fot the IP of the OpenVPN Server
echo Please enter the ip address of the OpenVPN Server:
read ip

#ask for the user to authenticate to the OpenVPN-Server with 
echo Please enter a username for the OpenVPN Server:
read remoteuser

#import the request
./easyrsa import-req /tmp/$name.req $name

#sign the request
./easyrsa sign-req client $name

#transmit the signed certificate back to the server using SCP
scp ~/easy-rsa/pki/issued/$name.crt $remotuser@$ip:/tmp/

#return to users home directory
cd ~
