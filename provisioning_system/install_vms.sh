#!/bin/bash

STRONG_NODES=(
  "s1:4"
  "s2:4"
)

MEDIUM_NODES=(
  "m1:4"
  "m2:4"
  "m3:4"
)

WEAK_NODES=(
  "w1:4"
  "w2:4"
  "w3:4"
  "w4:4"
  "w5:4"
)

HOSTS=(
  "c2n4:10"
)

ssh_commands=()

append_install_vm_command() {
  local device_type=$1
  local amount=$2

  for ((c = 4; c <= "$amount"; c++)); do
    local vm_name=$device_type-$c

    # TODO adapt cores, etc.
    ssh_commands+=("virt-install \
      --pxe \
      --network bridge:br0 \
      --network bridge=br1 \
      --name $vm_name \
      --ram=3072 \
      --vcpus=2 \
      --disk path=/var/lib/libvirt/images/$vm_name.img,size=20,format=raw \
      --osinfo detect=off; echo Installed VM $vm_name \n")
  done
}

for node in "${STRONG_NODES[@]}"; do
  DEVICE_TYPE=${node%%:*}
  AMOUNT=${node#*:}
  append_install_vm_command "$DEVICE_TYPE" "$AMOUNT"
done

for node in "${MEDIUM_NODES[@]}"; do
  DEVICE_TYPE=${node%%:*}
  AMOUNT=${node#*:}
  append_install_vm_command "$DEVICE_TYPE" "$AMOUNT"
done

for node in "${WEAK_NODES[@]}"; do
  DEVICE_TYPE=${node%%:*}
  AMOUNT=${node#*:}
  append_install_vm_command "$DEVICE_TYPE" "$AMOUNT"
done

counter=0
for host in "${HOSTS[@]}" ; do
    HOSTNAME=${host%%:*}
    AMOUNT=${host#*:}
    full_amount=$((counter+AMOUNT))
    while [[ $counter -lt $full_amount ]]; do
      ssh -T -o StrictHostKeyChecking=no "$HOSTNAME" "${ssh_commands[$counter]}"
      counter=$((counter + 1))
    done
done
