#!/bin/bash
sed -i '/http_proxy/d' /etc/apt/apt.conf.d/proxy.conf
sed -i '/https_proxy/d' /etc/apt/apt.conf.d/proxy.conf
sed -i '/http_proxy/d' /etc/environment
sed -i '/https_proxy/d' /etc/environment
sed -i '*.* @@10.15.1.18:5514' /etc/rsyslog.conf
