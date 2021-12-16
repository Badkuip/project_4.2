#!/bin/bash
static_ip_bool='no'
static_ip=''
hostname_pc='ubuntu-client'
sure_about_settings='no'
subnetmask='/24'
gateway=''
password_admin=''

# asks the user if he wants to set a static ip-address
ask_to_use_static_ip () {
  read -p "Do you want to set a static ip-address, yes/no?[$static_ip_bool]: " static_ip_bool_answer
  if [ "$static_ip_bool_answer" != "" ]; then
    check=$(echo $static_ip_bool_answer | awk '{print tolower($0)}')
    if [ "$check" = "yes" ]; then
      static_ip_bool='yes'
      ask_for_static_ip
    elif [ "$check" = "no" ]; then
      static_ip_bool="no"
    else
      echo 'Your answer was not valid, try again to continue.'
      ask_to_use_static_ip
    fi
  fi
}

# if the user wants to set a static ip-address this function will ask the user for a ip-address and checks if it is valid.
ask_for_static_ip () {
  read -p 'Enter the IP address you want to give to the machine: ' check_static_ip
  if [[ "$check_static_ip" =~ ^(([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-5][0-5])\.){3}([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-5][0-5])$ ]]; then
    static_ip=$check_static_ip
  else
    echo 'The given ip-address is not valid, try again to continue.'
    ask_for_static_ip
  fi
  ask_for_subnetmask
}

# ask the user for a subnetmask and checks if it is valid.
ask_for_subnetmask () {
  read -p 'Enter the subnetmask of the network (layout /24): ' subnetmask_to_check
  if [[ "$subnetmask_to_check" =~ ^\/[8-9]|[1-2][0-9] ]]; then
    subnetmask=$subnetmask_to_check
  else
    echo 'The subnetmask is invalid, try again to continue.'
    ask_for_subnetmask
  fi
  ask_for_gateway
}
#ask_for_static_ip

ask_for_gateway () {
  read -p 'Enter the gateway-address of the machine: ' check_gateway
  if [[ "$check_gateway" =~ ^(([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-5][0-5])\.){3}([0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-5][0-5])$ ]]; then
    gateway=$check_gateway
  else
    echo 'The given gateway-address is not valid, try again to continue.'
    ask_for_gateway
  fi
}

ask_for_hostname () {
  read -p "Witch hostname would you use. The default hostname is $hostname_pc: " hostname_pc
}

ask_for_admin_password () {
  read -p "Give the password of the Aministrator domain user: " password_admin
}

are_you_sure () {
  echo "Use a static ip-address: $static_ip_bool"
  echo "Static ip-address: $static_ip"
  echo "Hostname: $hostname_pc"
  echo "Administrator password: $password_admin" 
  read -p "are you sure to continue with the above settings, yes/no[$sure_about_settings]: " sure_about_settings
  if [ "$sure_about_settings" != "" ]; then
    check_sure=$(echo $sure_about_settings | awk '{print tolower($0)}')
    if [ "$check_sure" = "yes" ]; then
      sure_about_settings="yes"
    elif [ "$check_sure" = "no" ]; then
      exit 0
    else
      echo 'Your answer was not valid, try again to continue.'
      are_you_sure
    fi
  fi
}

ask_to_use_static_ip
ask_for_hostname
ask_for_admin_password
are_you_sure

# fix the broken apt-get function
sed -i -r 's@^deb http:\/\/[a-z]{0,3}.archive@deb http://old-releases@g' /etc/apt/sources.list
sed -i -r 's@^deb http:\/\/security@deb http://old-releases@g' /etc/apt/sources.list

# update en upgrade the client
apt-get update -y
apt-get upgrade -y

# install vm tools
apt-get install open-vm-tools -y
apt-get install open-vm-tools-desktop -y

# install thunderbird
apt install thunderbird -y

# install libreoffice genome
apt install libreoffice-gnome libreoffice -y

# install libreoffice plasma
apt install libreoffice-plasma libreoffice -y

# install libreoffice other desktop
apt install libreoffice -y

# install firefox
apt install firefox -y

# install clamav
apt-get install clamav clamav-daemon -y
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam

# Install 7zip.
#apt install p7zip-full -y

# install 7zip without package manager
if [ ! command -v wget > /dev/null 2>&1 ]; then
  exec apt-get install wget -y
fi

file='/usr/local/bin/7zz'
if ! type $file &> /dev/null; then
  echo 'test2'
  wget https://www.7-zip.org/a/7z2101-linux-x64.tar.xz && tar xf 7z2101-linux-x64.tar.xz
  tar xf 7z2101-linux-x64.tar.xz
  mv 7zz /usr/local/bin
fi

# Set proxy.
echo 'http_proxy="http://10.15.1.19:3128/"' >> /etc/environment
echo 'https_proxy="http://10.15.1.19:3128/"' >> /etc/environment
echo 'no_proxy="localhost,127.0.0.1,::1"'

# Set proxy apt-get.
touch /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::http::Proxy "http://10.15.1.19:3128/";' >> /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::https::Proxy "http://10.15.1.19:3128/";' >> /etc/apt/apt.conf.d/proxy.conf

# Change hostname.
hostnamectl set-hostname $hostname_pc.groep5.local

# Set ip for domain controller.
if grep - "nameserver ([0-9]{1,3}\.){3}[0-9]{1,3}" /etc/resolv.conf
then
  echo "nameserver 10.15.1.20" >> /etc/resolv.conf
else
  sed -e 's@nameserver ([0-9]{1,3}\.){3}[0-9]{1,3}@nameserver 10.15.1.20@' /etc/resolv.conf
fi

# Install tools to add client to domain.
apt update -y
apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit -y 2>&1 | tee /var/log/install_log_domain-tools.xt

# Search for domain.
#realm discover g05-dc01.groep5.local

# Login by the DC.
echo "$password_admin" | realm join -v -U Administrator g05-dc01.groep5.local

# Check if user wants static ip-address. If so, the static ip address wil be set.
set_static_ip () {
  if [ "$static_ip_bool" = 'yes' ]; then
    ethernetinterface=$(ip -o link show | awk '{print $2,$9}' | grep -P '(ens|eth)[0-9]{1,3}: UP' | awk 'FNR <= 1' | awk -F: '{print $1}')
    echo "  ethernets:" >> /etc/netplan/01-network-manager-all.yaml
    echo "    $ethernetinterface:" >> /etc/netplan/01-network-manager-all.yaml
    echo "      dhcp4: no" >> /etc/netplan/01-network-manager-all.yaml
    echo "      dhcp6: no" >> /etc/netplan/01-network-manager-all.yaml
    echo "      addresses: [$static_ip$subnetmask]" >> /etc/netplan/01-network-manager-all.yaml
    echo "      gateway4: $gateway" >> /etc/netplan/01-network-manager-all.yaml
    echo "      nameservers:" >> /etc/netplan/01-network-manager-all.yaml
    echo "        addresses: [10.15.1.20,8.8.8.8,8.8.4.4,1.1.1.1]" >> /etc/netplan/01-network-manager-all.yaml
  fi
}

set_static_ip

# Apply network changes.
netplan apply


# Set time sync.
sed -i 's@#NTP=@NTP=g05-dc01.groep5.local@g' /etc/systemd/timesyncd.conf
sed -i 's@#FallbackNTP=ntp.ubuntu.com@FallbackNTP=ntp.ubuntu.com@g' /etc/systemd/timesyncd.conf

# Make home directory for nieuw users.
pam-auth-update --enable mkhomedir

# Disables login list.
sed -i 's@# disable-user-list=true@disable-user-list=true@g' /etc/gdm3/greeter.dconf-defaults

# Makes shared folder mounting location.
mkdir /mnt/nfs-share

# Install pam-mount.
apt-get install libpam-mount -y

# Install hxtools.
apt-get install hxtools -y

# Install nfs-common.
apt-get install nfs-common -y

# Configure pam-mount to mount nfs homefolders.
sed -i '16 s@^$@<volume user="*" fstype="nfs" server="10.15.1.13" path="/srv/ldap-home/" mountpoint="home/" options="soft" />@g' /etc/security/pam_mount.conf.xml
sed -i 's@<logout wait="0" hup="no" term="no" kill="no" />@<logout wait="0" hup="yes" term="yes" kill="yes" />@g' /etc/security/pam_mount.conf.xml
sed -i 's@pam_mkhomedir.so@pam_mkhomedir.so skel=/etc/skel umask=0077@g' /etc/pam.d/common-session
# Permanent mount shared folder.
echo '10.15.1.13:/srv/nfs-share /mnt/nfs-share nfs defaults 0 0'  >> /etc/fstab

# Change home folder privalages.
sed -i -r 's@^UMASK.*022$@UMASK\t\t077@g' /etc/login.defs
sed -i -r 's@USERGROUPS_ENAB.*yes$@USERGROUPS_ENAB\tno@g' /etc/login.defs

# send logs to syslog server
echo "*.* @@10.15.1.18:5514" >> /etc/rsyslog.conf
systemctl restart rsyslog
systemctl enable rsyslog


# Install gconftool
#apt install gconf2 -y

# Remove update-manager
apt-get remove update-manager -y

# Stop popup from updatemanager
#gconftool -s --type bool /apps/update-notifier/auto_launch false

# Add client to authentication server.
#domainjoin-cli join domain_name domain_administrative_user

# Restarts the computer.
read -p 'The pc must be restarted to apply all changes, press enter to continue.' restart
reboot
