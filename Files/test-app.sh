#!/bin/sh
# This command is supposed to be run as root, or by a Custom Script Extension if deployed on an Azure VM

apt-get -y update
apt-get -y install python3-pip python3-dev build-essential curl libssl1.1 libssl-dev libpq-dev python-dev

#parameters
export SQL_SERVER_USERNAME=$1
export SQL_SERVER_PASSWORD=$2
export SQL_SERVER_DB=$3
export SQL_SERVER_FQDN=$4
export PORT=$5

apt-get update -y --fix-missing

wget https://raw.githubusercontent.com/erjosito/whoami/master/api/sql_api.py
wget https://raw.githubusercontent.com/erjosito/whoami/master/api/requirements.txt
pip3 install -r requirements.txt

# Run app
nohup python3 sql_api.py &

