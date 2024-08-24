# PXE Boot
# PXE Server at 192.168.1.20

##########################################################################
# Configure PXE Server
# https://www.server-world.info/en/note?os=CentOS_Stream_9&p=pxe&f=1

# Install and start TFTP
dnf -y install tftp-server
systemctl enable --now tftp.socket

# If Firewalld is running, allow TFTP service
firewall-cmd --add-service=tftp
firewall-cmd --runtime-to-permanent

##########################################################################
# Configure DHCP server
# https://www.server-world.info/en/note?os=CentOS_Stream_9&p=dhcp

# Install and Configure DHCP
dnf -y install dhcp-server
vim /etc/dhcp/dhcpd.conf

# Add the following content to the file:

#
# DHCP Server Configuration file.
#   see /usr/share/doc/dhcp-server/dhcpd.conf.example
#   see dhcpd.conf(5) man page
#
# create new
# specify domain name
#option domain-name     "test.at";
# specify DNS server's hostname or IP address
option domain-name-servers     192.168.1.1;
# default lease time
default-lease-time 600;
# max lease time
max-lease-time 7200;
# this DHCP server to be declared valid
authoritative;
# specify network address and subnetmask

option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

subnet 192.168.1.0 netmask 255.255.255.0 {
    # specify the range of lease IP address
    range dynamic-bootp 192.168.1.200 192.168.1.254;
    # specify broadcast address
    option broadcast-address 192.168.1.255;
    # specify gateway
    option routers 192.168.1.1;

    # add follows
    class "pxeclients" {
        match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
        # PXE servers hostname or IP address
        next-server 192.168.1.20;

        if option architecture-type = 00:07 {
            filename "BOOTX64.EFI";
        }
        else {
            filename "pxelinux.0";
        }
    }

}
# EOF

# Turn off other DHCP servers if they are running. E.g., on the router

systemctl enable --now dhcpd

# If Firewalld is running, allow DHCP service
firewall-cmd --add-service=dhcp
firewall-cmd --runtime-to-permanent

##########################################################################
# Network Installation
# https://www.server-world.info/en/note?os=CentOS_Stream_9&p=pxe&f=2

# Download Rocky Linux 9 OSI image under [/home]

wget https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.1-x86_64-minimal.iso 
sync

dnf -y install syslinux

cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

mkdir -p /var/pxe/rocky-9 

mkdir /var/lib/tftpboot/rocky-9

# Create service to mount ISO at boot
# https://medium.com/@benmorel/creating-a-linux-service-with-systemd-611b5c8b91d6

vim /etc/systemd/system/mount-pxe.service

# Add following content to the file:
[Unit]
Description=Mount PXE loop device service
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/bin/bash -c "mount -t iso9660 -o loop,ro /home/Rocky-9.1-x86_64-minimal.iso /var/pxe/rocky-9"

[Install]
WantedBy=multi-user.target
# EOF

systemctl start mount-pxe
systemctl enable mount-pxe
systemctl status mount-pxe

# Should show already mounted when running command below
mount -t iso9660 -o loop,ro /home/Rocky-9.1-x86_64-minimal.iso /var/pxe/rocky-9

cp /var/pxe/rocky-9/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/rocky-9/

cp /usr/share/syslinux/{menu.c32,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} /var/lib/tftpboot/

mkdir /var/lib/tftpboot/pxelinux.cfg

vim /var/lib/tftpboot/pxelinux.cfg/default

# Add the following content to the file:

# create new
# replace PXE servers hostname or IP address to your own one
default vesamenu.c32
prompt 1
timeout 60

display boot.msg

label linux
  menu label ^Install Rocky 9 Minimal
  menu default
  kernel rocky-9/vmlinuz
  append initrd=rocky-9/initrd.img ip=dhcp inst.repo=http://192.168.1.20/rocky-9
label vesa
  menu label Install Rocky 9 Minimal with ^basic video driver
  kernel rocky-9/vmlinuz
  append initrd=rocky-9/initrd.img ip=dhcp inst.xdriver=vesa nomodeset inst.repo=http://192.168.1.20/rocky-9
label rescue
  menu label ^Rescue installed system
  kernel rocky-9/vmlinuz
  append initrd=rocky-9/initrd.img rescue
label local
  menu label Boot from ^local drive
  localboot 0xffff

#EOF

# Install Apache httpd
# https://www.server-world.info/en/note?os=CentOS_Stream_9&p=httpd
dnf -y install httpd

# Rename or remove welcome page
mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.org

# Configure httpd
vim /etc/httpd/conf/httpd.conf

# Change the following content to the file:

# line 100 : change to your server's name
ServerName 192.168.1.20:80

# line 149 : change (remove [Indexes])
Options FollowSymLinks

# line 156 : change
AllowOverride All

# line 169 : add file name that it can access only with directory's name
DirectoryIndex index.html index.php index.cgi

# add follows to the end
# server's response header
ServerTokens Prod

#EOF

systemctl enable --now httpd

# If Firewalld is running, allow HTTP service
firewall-cmd --add-service=http
firewall-cmd --runtime-to-permanent

# Create a HTML test page and access to it from any client computer with web browser. It's OK if a page is shown.
vim /var/www/html/index.html

<html>
    <body>
        <div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
            Test Page
        </div>
    </body>
</html>


vim /etc/httpd/conf.d/pxeboot.conf

# Add the following content to the file:

# create new
Alias /rocky-9 /var/pxe/rocky-9
<Directory /var/pxe/rocky-9>
    Options Indexes FollowSymLinks
    # access permission
    Require ip 127.0.0.1 192.168.1.0/24
</Directory>
# EOF

systemctl restart httpd

# Should find installation folder on http://192.168.1.20/rocky-9/


##########################################################################
# Network Installation: Kickstart

# Configure Kickstart settings

mkdir /var/www/html/ks
vim /var/www/html/ks/rocky-9-ks.cfg

# Add the following content to the file:

# create new
# graphical installation
graphical

# reboot after installing
reboot

%addon com_redhat_kdump --disable
%end

# installation source (Base)
url --url="http://192.168.1.20/rocky-9"

# installation packages
%packages
@^minimal-environment
%end

# keyboard layouts
keyboard --xlayouts='us'

# system locale
lang en_US.UTF-8

# network settings
network --hostname=localhost.localdomain
# TODO needed?
network --hostname=test

# enable first boot setup
firstboot --enable

# initialize all partition tables
clearpart --none --initlabel

# partitioning
# for [/boot/efi], it needs only for UEFI clients
part / --fstype="xfs" --ondisk=sda --size=10000 --grow

# system timezone
timezone Europe/Vienna --utc

# root password
rootpw --iscrypted --allow-ssh $6$rlnGNGTa3rV3W5lm$yD0TIWLORlH.Aj/B1zlcoSb3VZ4qVVZwzjNIL0QWKmq5whge7fT7Zaio4kD5BQjGySxaE4d5zms602M6NF/hO/

%post
mkdir /root/.ssh
cat <<EOF >/root/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJY85iVW0OwMfSwj2N8XWxHa9wtCP+pbVfZDnCHjRuPZ DSG-Gitlab
EOF

chmod 0700 /root/.ssh
chmod 0600 /root/.ssh/authorized_keys

restorecon -R /root/.ssh/

%end

# EOF

chmod 644 /var/www/html/ks/rocky-9.cfg 

vim /var/lib/tftpboot/pxelinux.cfg/default

# Change like follows
# create new
# replace PXE servers hostname or IP address to your own one
default vesamenu.c32
prompt 1
timeout 60

display boot.msg

label linux
  menu label ^Install Rocky 9 Minimal
  menu default
  kernel rocky-9/vmlinuz
  append initrd=rocky-9/initrd.img ip=dhcp inst.ks=http://192.168.1.20/ks/rocky-9-ks.cfg
...
# EOF

##########################################################################
# Enable network booting on BIOS settings of client computer and start it, then installation menu you set is shown, push Enter key to proceed to install.

virt-install --pxe --network bridge:br0 --name guest1 --ram=4096 --vcpus=4 --disk path=/var/lib/libvirt/images/guest1.img,size=20,format=raw --osinfo detect=off

# Clean up if needed
virsh destroy guest1
virsh undefine VM_NAME
rm -rf /var/lib/libvirt/images/guest1.img
