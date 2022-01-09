#!/bin/bash
service=''
exitcode=''

# function that checks exit code
check_exitcode () {
 if [$exitcode = '1']; then
  tput setaf 1; echo "$service not running"
}

# check nfs is running
pgrep -x nfs-server.service
$service='nfs-server.service'
exitcode=$(echo $?) 
check_exitcode

# check nfs is running
pgrep -x firewall-cmd.service
$service='firewall-cmd.service'
exitcode=$(echo $?) 
check_exitcode
