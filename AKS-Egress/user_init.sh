#!/bin/bash

cd /home/avtxadmin/.ssh

echo -e "ssh-rsa 1Public2SSH3Key" > /home/avtxadmin/.ssh/id_rsa.pub
echo -e "-----BEGIN OPENSSH PRIVATE KEY-----
Enter your private SSH key
-----END OPENSSH PRIVATE KEY-----" > /home/avtxadmin/.ssh/id_rsa



chmod 600 /home/avtxadmin/.ssh/id_rsa
chmod 644 /home/avtxadmin/.ssh/id_rsa.pub

chown -R avtxadmin /home/avtxadmin/.ssh

chmod 600 /home/avtxadmin/.ssh/id_rsa
chmod 644 /home/avtxadmin/.ssh/id_rsa.pub