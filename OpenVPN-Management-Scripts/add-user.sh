#!/bin/bash
#########################################################################
##this script will add a user to the OpenVPN server and generate the   ##
##request and key files, it will then move the key to its proper place ##
##and send the request to the Certificate Authoritry for signing.      ##
##this script runs locally on the OpenVPN Server                       ##
##                                                                     ##
##Script Author: Dylan A King                                          ##
#########################################################################

#change to easy-rsa directory
cd ~/easy-rsa

#ask the user for name of the client
echo Please enter the common-name of the client:
read name

#ask for IP of Certificate Authoritry
echo Please enter the IP address of the Certificate Authority:
read ip

#ask for the user to authenticate with the Certificate Authoritry
echo Please enter the username for the Certificate Authority:
read remoteuser

#generate a request to be signed by the Certificate Authority
./easyrsa gen-req "$name" nopass

#move new clients key to the correct directory
cp pki/private/"$name".key ~/client-configs/keys/ 

#transmit the request to the CA via scp
scp pki/reqs/"$name".req "$remoteuser"@"$ip":/tmp/

#return home
cd ~
