#!/bin/bash
service=''
exitcode=''
folder=''
string=''
substring=''

# function that checks exitcode for services, to test if service is running
check_service () {
  systemctl is-active --quiet $service
  exitcode=$(echo $?)
  if [ ! $exitcode = '0' ]; then
    tput setaf 1; echo "$service not running"
  fi
  tput setaf 7
}

# checking if nfs-server is running
service='nfs-server'
check_service

# checking if firewalld is running
service='firewalld'
check_service



# check if substring in string/text
check_string () {
  if [[ ! "$string" == *"$substring"* ]]; then
    tput setaf 1; echo "$substring is not found"
  fi
  tput setaf 7
}

# checking if nsf folders are in exportfs
string=$(exportfs)
substring="/srv/ldap-home	10.15.1.0/24"
check_string
substring="/srv/nfs-share	10.15.1.0/24"

# checking if firewall settings exists
check_string
string=$(firewall-cmd --list-service)
substring="nfs"
check_string
substring="rpc-bind"
check_string
substring="mountd"


# function that checks if folder exist
check_folder() {
  if [ ! -d "$folder" ]; then
    tput setaf 1; echo "$folder does not exist." >&2
  fi
  tput setaf 7
}

# check if nfs folders exist
folder='/srv/ldap-home'
check_folder
folder='/srv/nfs-share'
check_folder

# check if permissions of nfs folders are correct
string=$(stat -c "%A %U %G %N" /srv/ldap-home)
substring="drwxrwxrwx nobody nobody '/srv/ldap-home'"
check_string
string=$(stat -c "%A %U %G %N" /srv/nfs-share)
substring="drwxrwxrwx nobody nobody '/srv/nfs-share'"
check_string



# check network connection
check_network () {
  tput setaf 1 
  ping -q -c1 8.8.8.8 &>/dev/null || echo 'The computer has no network connection'
  tput setaf 7
}
check_network



# script end
tput setaf 2; echo 'Test script has run successfully.'
tput setaf 7
