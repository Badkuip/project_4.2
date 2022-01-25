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
  read -p "Give the password of the Administrator domain user: " password_admin
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
# install libreoffice other desktop
apt install libreoffice -y

# install firefox
apt install firefox -y

# install clamav
apt-get install clamav clamav-daemon -y
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam

# install 7zip without package manager
if [ ! command -v wget > /dev/null 2>&1 ]; then
  exec apt-get install wget -y
fi
file='/usr/local/bin/7zz'
if ! type $file &> /dev/null; then
  wget https://www.7-zip.org/a/7z2101-linux-x64.tar.xz && tar xf 7z2101-linux-x64.tar.xz
  tar xf 7z2101-linux-x64.tar.xz
  mv 7zz /usr/local/bin
fi

# Set proxy.
echo 'http_proxy="http://10.20.6.30:3128/"' >> /etc/environment
echo 'https_proxy="http://10.20.6.30:3128/"' >> /etc/environment
# Set proxy apt-get.
touch /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::http::Proxy "http://10.20.6.30:3128/";' >> /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::https::Proxy "http://10.20.6.30:3128/";' >> /etc/apt/apt.conf.d/proxy.conf

# Set ip for domain controller.
if grep - "nameserver ([0-9]{1,3}\.){3}[0-9]{1,3}" /etc/resolv.conf
then
  echo "nameserver 10.20.6.2" >> /etc/resolv.conf
else
  sed -e 's@nameserver ([0-9]{1,3}\.){3}[0-9]{1,3}@nameserver 10.20.6.2@' /etc/resolv.conf
fi

# update client before adding it to the domain
apt update -y

# Install tools to add client to domain.
apt install -y sssd-ad sssd-tools realmd adcli

# Make kerberos config file.
echo "[libdefaults]" > /etc/krb5.conf
echo "default_realm = uvi.nl" > /etc/krb5.conf
echo "rdns = false" > /etc/krb5.conf

# Install kerberos tools.
apt install -y krb5-user sssd-krb5

# Change the hostname of the client.
hostnamectl set-hostname $hostname_pc.uvi.nl

# Login ad the DC, and add the client to the domain.
echo "$password_admin" | realm join -v -U Administrator WIN-DC-1.uvi.nl

# Make home directory for nieuw users.
pam-auth-update --enable mkhomedir

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
    echo "        addresses: [10.20.6.2,10.20.6.3,8.8.8.8,8.8.4.4,1.1.1.1]" >> /etc/netplan/01-network-manager-all.yaml
  fi
}
set_static_ip

# Apply network changes.
netplan apply

# Set time sync.
sed -i 's@#NTP=@NTP=lnx-ntp.uvi.nl@g' /etc/systemd/timesyncd.conf
sed -i 's@#FallbackNTP=ntp.ubuntu.com@FallbackNTP=ntp.ubuntu.com@g' /etc/systemd/timesyncd.conf


# Disables login list.
sed -i 's@# disable-user-list=true@disable-user-list=true@g' /etc/gdm3/greeter.dconf-defaults

# Change home folder privalages.
sed -i -r 's@^UMASK.*022$@UMASK\t\t077@g' /etc/login.defs
sed -i -r 's@USERGROUPS_ENAB.*yes$@USERGROUPS_ENAB\tno@g' /etc/login.defs

# send logs to syslog server
echo "*.* @10.20.6.4:514" >> /etc/syslog.conf
/etc/rc.d/init.d/syslog restart

# Remove update manager.
apt-get remove update-manager -y

# Restarts the computer.
read -p 'The pc must be restarted to apply all changes, press enter to continue.' restart
reboot
