#!/bin/bash
service=''
exitcode=''
program=''

# function that checks exitcode for services, to test if service is running
check_exitcode () {
  if [ ! $exitcode = '0' ]; then
    tput setaf 1; echo "$service not running"
  fi
  tput setaf 7
}

# function that checks fi program is installed
check_program () {
  if [ ! -x "$(command -v $program)" ]; then
    tput setaf 1; echo "$program is not installed." >&2
  fi
  tput setaf 7
}


# example for checking if a service (nfs-server) is running
service='nfs-server'
systemctl is-active --quiet $service
exitcode=$(echo $?)
check_exitcode

# exampel for checking if program (firefox) is installed
program='firefox'
check_program
