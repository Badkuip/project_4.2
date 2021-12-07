#!/bin/bash

ip_address='10.15.1.13'
subnetmask='24'
gateway='10.15.1.1'
dns_server='10.15.1.20'

dnf install nfs-utils
systemctl start nfs-server.service
systemctl enable nfs-server.service

ethernetinterface=$(ip -o link show | awk '{print $2,$9}' | grep -P '(ens|eth)[0-9]{1,3}: UP' | awk 'FNR <= 1' | awk -F: '{print $1}')

sed -i -r "s@BOOTPROTO=dhcp@BOOTPROTO=none@g" /etc/sysconfig/network-scripts/ifcfg-$ethernetinterface
echo "IPADDR=$ip_address" >> /etc/sysconfig/network-scripts/ifcfg-$ethernetinterface
echo "PREFIX=$subnetmask" >> /etc/sysconfig/network-scripts/ifcfg-$ethernetinterface
echo "GATEWAY=$gateway" >> /etc/sysconfig/network-scripts/ifcfg-$ethernetinterface
echo "DNS1=$dns_server" >> /etc/sysconfig/network-scripts/ifcfg-$ethernetinterface

mkdir /srv/ldap-home
mkdir /srv/nfs-share
chown nobody:nobody ldap-home
chown nobody:nobody nfs-share

# echo /srv/ldap-home 10.15.1.0/24(rwx, sync, soft)
echo '/srv/ladp-home 10.15.1.0/24(rw,no_root_squash,no_subtree_check,no_wdelay,sync)' >> /etc/exports
echo '/srv/nfs-share 10.15.1.0/24(rw,no_root_squash,no_subtree_check,no_wdelay,sync)' >> /etc/exports
exportfs -arv
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload
