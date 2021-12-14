#!/bin/bash
amount_of_home_folders=$(ls -l /home/ | grep ^d | wc -l)
amount_of_nfs_folders=$(ls -l /srv/ldap-home/ | grep ^d | wc -l)

if [ $amount_of_home_folders != $amount_of_nfs_folders ]; then
  for d in /home/*; do
    if [ ! -d "/srv/ldap-home/$(basename $d)@groep5.local" ]; then
      cp -r "$d" "/srv/ldap-home/$(basename $d)@groep5.local"
    fi
  done
fi
