#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install iperf3 -y
sudo apt install build-essential -y
sudo apt install git -y

git clone https://github.com/Microsoft/ntttcp-for-linux
cd ntttcp-for-linux/src

sudo su
make && make install