#!/bin/bash

apt-get update
apt-get install -y curl apt-transport-https gnupg

# Add Microsoft package repo
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl -sSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list \
  -o /etc/apt/sources.list.d/microsoft-prod.list

apt-get update
apt-get install -y openssh-server powershell

usermod -s /usr/bin/pwsh admin

touch /tmp/userdata_done
