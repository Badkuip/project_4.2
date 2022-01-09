#!/bin/bash
service=''
exitcode=''
program=''
string=''
substring=''
folder=''

# function that checks exitcode for services, to test if service is running
check_service () {
  systemctl is-active --quiet $service
  exitcode=$(echo $?)
  if [ ! $exitcode = '0' ]; then
    tput setaf 1; echo "$service not running"
  fi
  tput setaf 7
}

# example for checking if a service (nfs-server) is running
service='nfs-server'
check_service



# function that checks if program is installed
check_program () {
  if [ ! -x "$(command -v $program)" ]; then
    tput setaf 1; echo "$program is not installed." >&2
  fi
  tput setaf 7
}

# example for checking if program (firefox) is installed
program='firefox'
check_program



# check if substring in string/text
check_string () {
  if [[ ! "$string" == *"$substring"* ]]; then
    tput setaf 1; echo "$substring is not in string"
  fi
  tput setaf 7
}

# example for checking if a substring is in a string
string=$(exportfs)
substring="/srv/ldap-home	192.168.20.0/24"
check_string



# check network connection
check_network () {
  tput setaf 1 
  ping -q -c1 8.8.8.8 &>/dev/null || echo 'The computer has no network connection'
  tput setaf 7
}
check_network



# function that checks if folder exists is installed
check_folder() {
  if [ ! -d "$folder" ]; then
    tput setaf 1; echo "$folder does not exist." >&2
  fi
  tput setaf 7
}

# example check if folders exist
folder='/srv/ldap-home'
check_folder
