#!/bin/bash

HOSTS=(
  "c2n1"
  "c2n3"
  "c2n4"
)

for host in "${HOSTS[@]}"; do
  ip_addresses=()
  mac_addresses=$(ssh -T -o StrictHostKeyChecking=no "$host" <<'EOF'
  for i in $(virsh list --all --name); do
      if [[ $i =~ ^(s|m|w)[1-9][0-9]?-[1-9][0-9]?$ ]]
      then
        mac_address=$(virsh -q domiflist "$i" | awk 'NR==1{print $5}')
        echo "$i=$mac_address"
      fi
  done
EOF
)
  result=$(ssh -T -o StrictHostKeyChecking=no pxe "for c in $(echo $mac_addresses) ; do hostname=\${c%%=*}; mac_address=\${c#*=}; ip_address=\$(ip neigh | grep -i \$mac_address | awk '{print \$1}'); echo \$hostname=\$ip_address ; done")
  for c in $result ; do
      ip_addresses+=("$c")
  done

  for c in "${ip_addresses[@]}" ; do
      hostname=${c%%=*};
      ip_address=${c#*=};
      echo "${hostname} <-> ${ip_address}"
      last_ip_part=$(echo "$ip_address" | awk -F "." '{print $4}')
      ssh -T -o StrictHostKeyChecking=no -J "$host" "root@${ip_address}" "hostnamectl set-hostname $hostname ; hostnamectl ; nmcli connection modify ens4 ipv4.addresses 10.0.0.${last_ip_part}/24 ipv4.method manual ; reboot"
      {
        echo "Host ${hostname}"
        echo -e "\tHostName ${ip_address}"
        echo -e "\tProxyJump ${host}"
        echo -e "\tUser root\n"
      } >> ~/.ssh/config.d/rcs
  done
done
