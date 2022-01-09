#!/bin/bash
service=''
exitcode=''

# function that checks exit code
check_exitcode () {
  if [$exitcode = '1']; then
    tput setaf 1; echo "$service not running"
  if
}

# check nfs is running
exitcode=$(systemctl is-active --quiet nfs-server.service | echo $?)
$service='nfs-server.service'
check_exitcode

# check nfs is running
exitcode=$(systemctl is-active --quiet firewalld | echo $?)
$service='firewall-cmd'
check_exitcode

echo 'Test script has run.'
