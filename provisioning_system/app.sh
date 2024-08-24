#!/bin/bash

copy_files() {
  local host=$1
  local device_type="${host%%-*}"

  printf "%s %s\n" "${host}" "${device_type}"

  scp -r ./app/"${device_type}"/* "${host}":/root/
  scp -r ./app/rain-cloud-system-1.0.0-exec.jar "${host}":/root/
  scp -r ./app/emitter "${host}":/root/
  scp -r ./app/function_time "${host}":/root/
}

replace_with_local_ip() {
  local host=$1
  local remote_ip=$2
  last_ip_part=$(echo "$remote_ip" | awk -F "." '{print $4}')
  local ip="10.0.0.${last_ip_part}"
  ssh -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.localIP=.*/comm.localIP=$ip/' /root/application.properties"
}

install_dependencies() {
  local host=$1
  ssh -T -o StrictHostKeyChecking=no "$host" "dnf -y update; dnf -y upgrade; dnf -y install vim nc java-11-openjdk"
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

          copy_files "$host"
          replace_with_local_ip "$host" "$ip"
          # install_dependencies "$host"

          printf "Finished setting up %s\n" "${host}"
          printf "#####################################################################\n"
          unset host ip
        ;;
      esac
  esac
done
