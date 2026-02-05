sudo adduser user1
sudo adduser user2

sudo mkdir -p /home/user1/.ssh
sudo mkdir -p /home/user2/.ssh

sudo sh -c 'echo "ssh-ed25519 AAAA... user1@yourdomain" >> /home/user1/.ssh/authorized_keys'
sudo sh -c 'echo "ssh-ed25519 AAAA... user2@yourdomain" >> /home/user2/.ssh/authorized_keys'

sudo chown -R user1:user1 /home/user1/.ssh
sudo chown -R user2:user2 /home/user2/.ssh
sudo chmod 700 /home/user1/.ssh /home/user2/.ssh
sudo chmod 600 /home/user1/.ssh/authorized_keys /home/user2/.ssh/authorized_keys

~$ sudo adduser drumyantsev sudo
info: Adding user `drumyantsev' to group `sudo' ...

~$ sudo grep '^sudo:' /etc/group
sudo:x:27:ubuntu,ailves,mlazarev,amishutkin,jjjones,jlew,drumyantsev