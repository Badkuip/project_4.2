#!/bin/bash

apt-get install nfs-common -y

touch /srv/sync_script.sh
chmod +x /srv/sync_script.sh
tee -a /srv/sync_script.sh <<EOF
'#!/bin/bash'
'amount_of_home_folders=$(ls -l /home/ | grep ^d | wc -l)'
'amount_of_nfs_folders=$(ls -l /srv/nfs-home/ | grep ^d | wc -l)'
((amount_of_nfs_folders++))
'if [ $amount_of_home_folders != $amount_of_nfs_folders ]; then'
  'for d in /home/*; do'
    'if [ ! -d "/srv/nfs-home/$(basename $d)@groep5.local" ]; then'
      'cp -r "$d" "/srv/nfs-home/$(basename $d)@groep5.local"'
    'fi'
  'done'
'fi'
EOF

mkdir /srv/nfs-home
echo '10.15.1.13:/srv/ldap-home /srv/nfs-home nfs defaults 0 0'  >> /etc/fstab
echo "* * * * * jroot /srv/sync_script.sh >/dev/null 2>&1" >> /etc/crontab
mount 10.15.1.13:/srv/ldap-home /srv/nfs-home
