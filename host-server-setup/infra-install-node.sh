#.bashrc
echo "HISTSIZE=100000" >> .bashrc
echo "HISTFILESIZE=100000" >> .bashrc

#swapfile
fallocate -l 1024M /swapfile && dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile && ls -lh /swapfile && mkswap /swapfile && swapon /swapfile && echo "/swapfile none swap defaults 0 0" >> /etc/fstab

dnf config-manager --set-enabled crb

#packages
dnf -y install epel-release
dnf -y install vim tree net-tools tar wget rsync screen nc tmux htop bash-completion
dnf -y install tcpdump nmap traceroute bind-utils nfs-utils
dnf -y install dnf-automatic fail2ban
dnf -y update

#start tmux session because
tmux

#useful tmux commands
tmux ls
tmux attach

#fail2ban
echo "[DEFAULT]" > /etc/fail2ban/jail.local
echo "bantime = 600" >> /etc/fail2ban/jail.local
echo "findtime = 600" >> /etc/fail2ban/jail.local
echo "maxretry = 3" >> /etc/fail2ban/jail.local
echo "[sshd]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
systemctl enable --now fail2ban.service

#deactivate SELINUX
echo "SELINUX=disabled" > /etc/selinux/config

#auto-security updates
dnf -y install dnf-automatic
sed -i -e 's/upgrade_type = default/upgrade_type = security/g' /etc/dnf/automatic.conf
sed -i -e 's/apply_updates = no/apply_updates = yes/g' /etc/dnf/automatic.conf
systemctl enable --now dnf-automatic.timer
systemctl status dnf-automatic.timer
dnf-automatic
cat /var/log/dnf.rpm.log |grep "Inst"

reboot

#checks after reboot
getenforce
systemctl status dnf-automatic.timer
free -h

### Here starts KVM Virtualizaion Host Installation

### BR0 set on rcs1
DEV="enp4s0"
echo $DEV
nmcli connection add type bridge autoconnect yes bridge.stp no multicast-snooping no ipv6.method disabled con-name br0 ifname br0
nmcli connection modify br0 ipv4.addresses 192.168.1.11/24 ipv4.method manual
nmcli connection modify br0 ipv4.gateway 192.168.1.1
nmcli connection modify br0 ipv4.dns "192.168.1.1"
nmcli connection del $DEV ; sleep 10 && nmcli connection add type bridge-slave autoconnect yes con-name $DEV ifname $DEV master br0 && reboot

#check br0
ip a
nmcli dev status

#install kvm host
lsmod | grep kvm
dnf -y install qemu-kvm libvirt virt-install
systemctl enable --now libvirtd

#add kvm pool
mkdir -p /var/lib/libvirt/install
cd /var/lib/libvirt/install
wget https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.1-x86_64-minimal.iso 

#install virt-manager to client system
dnf install virt-manager
apt install virt-manager

#test kvm host
virt-install --network bridge:br0 --name test --ram=4096 --vcpus=4 --disk path=/var/lib/libvirt/images/test.img,size=20,format=raw --cdrom /var/lib/libvirt/install/Rocky-9.1-x86_64-minimal.iso

#NetworkManager
#use only one "default Gateway" if you use "[X] Never use this network for default route" this option, NetworkManager deletes Gateway.
