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

# checking if clamav is running
service='clamav-freshclam'
check_service
# checking if rsyslog is running
service='rsyslog'
check_service



# function that checks if program is installed
check_program () {
  if [ ! -x "$(command -v $program)" ]; then
    tput setaf 1; echo "$program is not installed." >&2
  fi
  tput setaf 7
}

# checking if firefox is installed
program='firefox'
check_program

# checking libreoffice is installed
program='libreoffice'
check_program

# checking thunderbird is installed
program='thunderbird'
check_program

# checking 7zip is installed
program='7zz'
check_program

# checking realm is installed
program='realm'
check_program



# function that checks if substring in string/text
check_string () {
  if [[ ! "$string" == *"$substring"* ]]; then
    tput setaf 1; echo "$substring is not in string"
  fi
  tput setaf 7
}

# checking if proxy is set
string=$(cat /etc/environment)
substring='http_proxy="http://10.15.1.19:3128/"'
check_string
substring='https_proxy="http://10.15.1.19:3128/"'
check_string
# substring='no_proxy="localhost,127.0.0.1,::1"'
# check_string
string=$(cat /etc/apt/apt.conf.d/proxy.conf)
substring='Acquire::http::Proxy "http://10.15.1.19:3128/";'
check_string
substring='Acquire::https::Proxy "http://10.15.1.19:3128/";'
check_string

# checking if is pc in a domain
string=$(realm list)
substring='groep5.local'
check_string

# checking if time sync is configured
string=$(cat /etc/systemd/timesyncd.conf)
substring='NTP=g05-dc01.groep5.local'
check_string

# no function
substring='FallbackNTP=ntp.ubuntu.com'
check_string

# checking if login list is disabled (no function)
string=$(cat /etc/gdm3/greeter.dconf-defaults)
substring='disable-user-list=true'
check_string

# checking pam_mount configurations
string=$(cat /etc/security/pam_mount.conf.xml)
substring='<volume user="*" fstype="nfs" server="10.15.1.13" path="/srv/ldap-home/" mountpoint="home/" options="soft" />'
check_string
substring='<logout wait="0" hup="yes" term="yes" kill="yes" />'
check_string
string=$(cat /etc/pam.d/common-session)
substring='pam_mkhomedir.so skel=/etc/skel umask=0077'
check_string

# check nfs-share mount configuration
string=$(cat /etc/fstab)
substring='10.15.1.13:/srv/nfs-share /mnt/nfs-share nfs defaults 0 0'
check_string

# check homefolder privalage config
string=$(cat /etc/login.defs)
substring='UMASK		077'
check_string
substring='USERGROUPS_ENAB	no'
check_string

# check log configuration
string=$(cat /etc/rsyslog.conf)
substring='*.* @@10.15.1.18:5514'
check_string




# checks network connection
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

# check if nfs-share mount location exist
folder='/mnt/nfs-share'
check_folder

# script end
tput setaf 2; echo 'Test script has run successfully.'
tput setaf 7
