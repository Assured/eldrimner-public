#!/bin/bash

# This bash script is run as a preseed late command
# in-target
# as root

# Log to file
ELDLOG=/var/log/eldrimner-install.log

# PSK for manual LUKS unlock, passed from preseed script
DMDEVICE=$1
DEVICE=$2

#echo "[ELDRIMNER] PSK: $PSK" > $ELDLOG
echo "[ELDRIMNER] Installing packages..." >> $ELDLOG

# The .deb files need to be extracted into ELDPATH
ELDPATH="/opt/eldrimner/install"

# Unpack tarballs
for file in $ELDPATH/*.tar; do tar xf $file -C $ELDPATH/; done
tar xf $ELDPATH/attestca/tpm.tar -C /root/
chgrp tss /root/Tpm2AttestationCertificationAuthority/integration-test

# Install deb files
apt install -y $ELDPATH/libsapi0_1.4.0-1_amd64.deb
apt install -y $ELDPATH/libsapi-dev_1.4.0-1_amd64.deb
apt install -y $ELDPATH/tpm2-tools_3.0.4-1_amd64.deb
apt install -y $ELDPATH/clevis_10-1_amd64.deb
apt install -y $ELDPATH/clevis-luks_10-1_all.deb
apt install -y $ELDPATH/clevis-initramfs_10-1_amd64.deb

echo "[ELDRIMNER] Finished installing packages..." >> $ELDLOG
echo "[ELDRIMNER] Updating..." >> $ELDLOG

# Update packages
apt update 2>&1
apt -y upgrade 2>&1

echo "[ELDRIMNER] Finished updating..." >> $ELDLOG
echo "[ELDRIMNER] Installing tboot..." >> $ELDLOG

# Install tboot
apt install -y tboot 2>&1 >> $ELDLOG

# Install Java JRE (PoC Attestation CA)
apt install -y default-jre 2>&1 >> $ELDLOG

# Install SINIT files into /boot
# Only if needed
# cp $ELDPATH/sinit/*SINIT*.bin /boot/

# Prefer tboot in Grub
sed -Ei.bak 's/^\#?(GRUB_DEFAULT=).*/\1"tboot 1.9.6>0"/' /etc/default/grub
echo "[ELDRIMNER] Activated tboot..." >> $ELDLOG

#echo "[ELDRIMNER] Dumping keyfile..." >> $ELDLOG
#touch /root/luks_0.bin
#chmod 600 /root/luks_0.bin
#xxd -r -p - /root/luks_0.bin <<< $(dmsetup -c table ${DMDEVICE} --showkeys | cut -d" " -f5)

echo "[ELDRIMNER] update-initramfs and initialize luksmeta..." >> $ELDLOG

# Setup clevis and remove the preseed luks key
update-initramfs -u -k 'all' 2>&1 >> $ELDLOG
luksmeta init -nfd ${DEVICE} 2>&1 >> $ELDLOG

#echo "[ELDRIMNER] Modding clevis-luks-bind to allow master key file..." >> $ELDLOG
#cp /usr/bin/clevis-luks-bind /usr/bin/clevis-luks-bind.original
#cp $ELDPATH/clevis-luks-bind.edit /usr/bin/clevis-luks-bind

# ************************************************************************
# *** Needed: 1. Correct address to Tang host.                         ***
# *** Needed: 2. Correct payload/signature information for Tang host.  ***
# ***                                                                  ***
# *** Example below from a development server, specifying ECMR, P-521  ***
# ***    and various other settings                                    ***
# ************************************************************************
#
#echo "[ELDRIMNER] Binding tang server to LUKS slot..." >> $ELDLOG
# clevis luks bind -d ${DEVICE} -s 2 -mk /root/luks_0.bin tang '{"url": "http://...", "adv": {"payload":"eyJrZXlzIjpbeyJhbGciOiJFQ01SIiwiY3J2IjoiUC01MjEiLCJrZXlfb3BzIjpbImRlcml2ZUtleSJdLCJrdHkiOiJFQyIsIngiOiJBYkw2TzF4a0VHd3VQOVdVcmhIeFFNWjcxckFMYURwVjJpcmRBUUZ4cnA5NWVPdXZKWHJFWHdUeGxWdVVBWlJoa21QaU1nd2V5TWhJejEzeHBITnZRdXRuIiwieSI6IkFYdUxHMjAyb0NFc0NNdFcxdDBGd19zWlpSY3dSR2NPMXRfem91WU9teWFfT3lGN1FrWlMtX3pPWTc0YXBhS2hsZVZwcmY5NzBtM1B3dF95bjZxSGdYMWIifSx7ImFsZyI6IkVTNTEyIiwiY3J2IjoiUC01MjEiLCJrZXlfb3BzIjpbInZlcmlmeSJdLCJrdHkiOiJFQyIsIngiOiJBS3lHSEdKWnpJWlR2UUJsTTVNZE1kaG1xSGU0S3BNZWJrTVJWRTh4NnJhR1cxdFFKWXJwRUlvRmhWNDVJUy1mX3BTWkxVNWpkMG9IREZRVEdmLThzUWJqIiwieSI6IkFFdEstQUpoMmk1NzR0MHB3WVU2UmxYeFJHNU83dGZfeTQ4Q25OMWdnWEx3cGsxYnZjR2tLTGpNeGhsNWZQclQ0ZjJxUUhobzQzZDFBOHdqNTV5OG9aSkUifV19","protected":"eyJhbGciOiJFUzUxMiIsImN0eSI6Imp3ay1zZXQranNvbiJ9","signature":"Abh0FnbK73R64A9kzul8zr3P6Upc7WY0OkO3j_CUE8qC-kRKwUaNhMesYpIdtIygb-mXADsgV_U7P9W_ArH7y5BRAY7nH6RQ1VLSKdAinCwPgdA-Zr2fEJvSSHwGh5JhX5ESOe8A6Lg0cI4QBO5JKaD-9sBNbHLsX3n8n5jvhVZW0sCn"}}'

# Update Grub
echo "[ELDRIMNER] Update grub..." >> $ELDLOG
update-grub2 2>&1 >> $ELDLOG

echo "[ELDRIMNER] Message of the day..." >> $ELDLOG

# Set a fancy motd banner
cp $ELDPATH/motd /etc/motd


# Add trusted SSH key to user
# ************************************************************************
# *** Needed: 1. ssh key for system administration                     ***
# ***                                                                  ***
# *** Example below from a developer test key, not to be used for      ***
# ***    production.                                                   ***
# ************************************************************************
#
# echo "[ELDRIMNER] Adding ssh key..." >> $ELDLOG
# mkdir -m700 -p /home/andrimner/.ssh
# touch /home/andrimner/.ssh/authorized_keys
# chmod 600 /home/andrimner/.ssh/authorized_keys
# chown -R andrimner:andrimner /home/andrimner/.ssh
# echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+nhESfZz+0oU83ODlPEOui75nIpYdP4J9UOXdnn0vcc9rysUoHyh9Wf3TslMF1IiNdxn+YRuFs+xjUyL/AwPJg2hnmMXO8CK016Sxo7OL/NK/W53w3ZBMe7b+mPww9uTRJ5Yo7TDySc3EmyKLR/Zyaw2R0ln0Lq8EXJ0Y2v3hYdvq9igNZhzG90ht/Z49jJiHM2n63iRnwGYD05pxNlQPn/O1STRKX7pjcJDhclIw5dc+n4hvcAsTjgKrnNida2ix7ij8QEf3DERk3IsygpKmvX1qFm+ph3ieNGp+xfjFyMncMgBefQ6PM5q7RKd6zylg3SVWVsjt/qM21uCm2PbcH3H2Gi4sdC5+/Byuu7i9ZLlm7q1ajHZNNHIGOCYO3+mTlAQeYG0pzwt/JXc4RsMohCBMo40ERR6xO1iu6VKxganp9Tu6u+owU1fz6Eh8SW6XopZ6UJ2/QOOf7KQRfgK1fmqcF94nDh9xf4Qf8RK4mIVk7KJS2cC5LKE6TWNM3mm5iHbTlFv0I/LIKHSFeIBu+wdfM6XeAOdgkGeNGvoH5/3eZnJkTwok8EbTIT/IPb/60ApKC4riTNLIHWCWGdFnjmaX1Vh+0FFwaZDFHHlszTYcDuIZAkmOnpSBaKckhJjbwDrPMX9n640ONW/geQ4CrUIMktozO/5xTjYCnDYE5w== andrimner@eldrimner" >> /home/andrimner/.ssh/authorized_keys

echo "[ELDRIMNER] Modifying sshd_config..." >> $ELDLOG

# Modify sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

echo "[ELDRIMNER] Done..." >> $ELDLOG
