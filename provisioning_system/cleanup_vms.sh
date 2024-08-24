#!/bin/bash

HOSTS=(
  "c1n1"
  "c1n3"
  "c2n4"
)

for host in "${HOSTS[@]}"; do
  ssh -T -o StrictHostKeyChecking=no "$host" <<'EOF'
  for vm_name in $(virsh list --all --name); do
      if [[ $vm_name =~ ^(s|m|w)[1-9][0-9]?-[1-9][0-9]?$ ]]
      then
        virsh destroy "$vm_name"
        virsh undefine "$vm_name"
        rm -rf /var/lib/libvirt/images/"$vm_name".img
        printf "Cleaned up VM %s \n" "$vm_name"
      fi
  done
EOF
done

rm ~/.ssh/config.d/rcs
touch ~/.ssh/config.d/rcs
