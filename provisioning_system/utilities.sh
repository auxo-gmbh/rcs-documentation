#!/bin/bash

AMOUNT_NODES=100

nodes_100=(
  "s1-1"
  "s1-2"
  "s1-3"
  "s1-4"
  "s1-5"
  "s1-6"
  "s1-7"
  "s1-8"
  "s1-9"
  "s1-10"
  "s2-1"
  "s2-2"
  "s2-3"
  "s2-4"
  "s2-5"
  "s2-6"
  "s2-7"
  "s2-8"
  "s2-9"
  "s2-10"
  "m1-1"
  "m1-2"
  "m1-3"
  "m1-4"
  "m1-5"
  "m1-6"
  "m1-7"
  "m1-8"
  "m1-9"
  "m1-10"
  "m2-1"
  "m2-2"
  "m2-3"
  "m2-4"
  "m2-5"
  "m2-6"
  "m2-7"
  "m2-8"
  "m2-9"
  "m2-10"
  "m3-1"
  "m3-2"
  "m3-3"
  "m3-4"
  "m3-5"
  "m3-6"
  "m3-7"
  "m3-8"
  "m3-9"
  "m3-10"
  "w1-1"
  "w1-2"
  "w1-3"
  "w1-4"
  "w1-5"
  "w1-6"
  "w1-7"
  "w1-8"
  "w1-9"
  "w1-10"
  "w2-1"
  "w2-2"
  "w2-3"
  "w2-4"
  "w2-5"
  "w2-6"
  "w2-7"
  "w2-8"
  "w2-9"
  "w2-10"
  "w3-1"
  "w3-2"
  "w3-3"
  "w3-4"
  "w3-5"
  "w3-6"
  "w3-7"
  "w3-8"
  "w3-9"
  "w3-10"
  "w4-1"
  "w4-2"
  "w4-3"
  "w4-4"
  "w4-5"
  "w4-6"
  "w4-7"
  "w4-8"
  "w4-9"
  "w4-10"
  "w5-1"
  "w5-2"
  "w5-3"
  "w5-4"
  "w5-5"
  "w5-6"
  "w5-7"
  "w5-8"
  "w5-9"
  "w5-10"
)

nodes_filip=(
  "s1-2"
  "s2-2"
  "m1-2"
  "m2-2"
  "m3-2"
  "w1-2"
  "w2-2"
  "w3-2"
  "w4-2"
  "w5-2"
)

nodes_50_filip=(
  "s1-1"
  "s1-2"
  "s1-3"
  "s1-4"
  "s1-5"
  "s2-1"
  "s2-2"
  "s2-3"
  "s2-4"
  "s2-5"
  "m1-1"
  "m1-2"
  "m1-3"
  "m1-4"
  "m1-5"
  "m2-1"
  "m2-2"
  "m2-3"
  "m2-4"
  "m2-5"
  "m3-1"
  "m3-2"
  "m3-3"
  "m3-4"
  "m3-5"
  "w1-1"
  "w1-2"
  "w1-3"
  "w1-4"
  "w1-5"
  "w2-1"
  "w2-2"
  "w2-3"
  "w2-4"
  "w2-5"
  "w3-1"
  "w3-2"
  "w3-3"
  "w3-4"
  "w3-5"
  "w4-1"
  "w4-2"
  "w4-3"
  "w4-4"
  "w4-5"
  "w5-1"
  "w5-2"
  "w5-3"
  "w5-4"
  "w5-5"
)

nodes_worse=(
  "s1-1"
  "s2-1"
  "m1-1"
  "m2-1"
  "m3-1"
  "w1-1"
  "w2-1"
  "w3-1"
  "w4-1"
  "w5-1"
)

nodes_25_filip=(
  "s1-6"
  "s1-7"
  "s2-6"
  "s2-7"
  "s2-8"
  "m1-6"
  "m1-7"
  "m2-6"
  "m2-7"
  "m3-6"
  "m3-7"
  "m3-8"
  "w1-6"
  "w1-7"
  "w2-6"
  "w2-7"
  "w3-6"
  "w3-7"
  "w3-8"
  "w4-6"
  "w4-7"
  "w4-8"
  "w5-6"
  "w5-7"
  "w5-8"
)

nodes=("${nodes_25_filip[@]}")

change_property() {
  local host=$1
  local ip=$2

  # ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.includedIPs=.*/comm.includedIPs=193,121,142,238,218,189,243,145,157,161,226,215,159,180,160,144,222,137,171,229,154,253,138,182,241/' /root/application.properties"
  ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.minConnections=.*/comm.minConnections=4/' /root/application.properties"
  # ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^task.timeToLiveFactor=.*/task.timeToLiveFactor=10/' /root/application.properties"
  # ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^spring.rabbitmq.host=.*/spring.rabbitmq.host=128.131.202.233/' /root/application.properties"
  # ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.minRemoteIP=.*/comm.minRemoteIP=120/' /root/application.properties"
  # ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.maxRemoteIP=.*/comm.maxRemoteIP=254/' /root/application.properties"
}

remove_useless_folder() {
  local host=$1
  local device_type="${host%%-*}"

  ssh -T -o StrictHostKeyChecking=no "$host" "rm -rf $device_type"
}

startup_firewall() {
  local host=$1

  ssh -T -o StrictHostKeyChecking=no "$host" "systemctl start firewalld.service"
  ssh -T -o StrictHostKeyChecking=no "$host" "systemctl status firewalld.service"
}

shutdown_firewall() {
  local host=$1

  ssh -T -o StrictHostKeyChecking=no "$host" "systemctl stop firewalld.service"
  ssh -T -o StrictHostKeyChecking=no "$host" "systemctl status firewalld.service"
}

run_program() {
  local host=$1

  ssh -T -o StrictHostKeyChecking=no "$host" "timeout 60m java -Dspring.profiles.active=Gossips,remote -jar rain-cloud-system-1.0.0-exec.jar --spring.config.location=application.properties" &
}

reboot() {
  local host=$1
  ssh -T -o StrictHostKeyChecking=no "$host" "reboot"
}

shopt -s nocasematch
for word in $(grep -i "^[^#\S]*Host\(name\)\?" ~/.ssh/config.d/rcs | paste -s -); do
  case "$word" in
  "Host")
    type=host
    ;;
  "Hostname")
    type=hostname
    ;;
  *)
    case "$type" in
    "host")
      host=$word
      ;;
    "hostname")
      ip=$word

      if [ ${#nodes[@]} -eq 0 ] || [[ "${nodes[*]}" =~ ${host} ]]; then
        # startup_firewall "$host"
        shutdown_firewall "$host"
        # remove_useless_folder "$host"
        # change_property "$host" "$ip"
        # run_program "$host"
        # reboot "$host"

        printf "Finished utilities for %s\n" "${host}"
        printf "#####################################################################\n"
      fi

      unset host ip
      ;;
    esac
    ;;
  esac
done
