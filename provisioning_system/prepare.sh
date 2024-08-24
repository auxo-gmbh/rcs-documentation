#!/bin/bash

# !!!!!!!!!!!!!!!!
# TODO CHANGE BEFORE RUN
RABBIT_MQ_HOST=128.131.201.114
AMOUNT_NODES=50
NODES_FILE=nodes-50-worse
# !!!!!!!!!!!!!!!!

collected_included_ips() {
  local ips=()
  while IFS= read -r node; do
    last_ip_part=$(get_last_ip_part "$node")
    ips+=("$last_ip_part")
  done <$NODES_FILE

  included_ips_string=$(join_arr , "${ips[@]}")
  echo "$included_ips_string"
}

join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

get_last_ip_part() {
  local host=$1
  local ip
  local last_part

  ip=$(ssh -T -G "$host" | awk '/^hostname / { print $2 }')
  last_part=$(echo "$ip" | awk -F "." '{print $4}')
  printf "%s\n" "$last_part"
}

calculate_min_ip() {
  local included_ips=$1
  local min_ip="255"

  for ip in $(echo "$included_ips" | sed "s/,/ /g"); do
    ((ip < min_ip)) && min_ip=$ip
  done

  printf "%s\n" "$min_ip"
}

calculate_max_ip() {
  local included_ips=$1
  local max_ip="0"

  for ip in $(echo "$included_ips" | sed "s/,/ /g"); do
    ((ip > max_ip)) && max_ip=$ip
  done

  printf "%s\n" "$max_ip"
}

reboot_nodes() {
  while IFS= read -r node; do
    ssh -n -T -o StrictHostKeyChecking=no "$node" "reboot"
    printf "################### Rebooted %s ###################\n" "$node"
  done <$NODES_FILE
}

wait_till_nodes_online() {
  sleep 120
}

shutdown_firewalls() {
  while IFS= read -r node; do
    ssh -n -T -o StrictHostKeyChecking=no "$node" "systemctl stop firewalld.service && systemctl status firewalld.service"
    printf "################### Firewall deactivated for %s ###################\n" "$node"
  done <$NODES_FILE
}

set_application_properties() {
  local included_ips=$1
  local min_ip=$2
  local max_ip=$3

  while IFS= read -r node; do
    set_node_property "$node" "$included_ips" "$min_ip" "$max_ip"
  done <$NODES_FILE
}

set_node_property() {
  local host=$1
  local included_ips=$2
  local min_ip=$3
  local max_ip=$4

  ssh -n -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.includedIPs=.*/comm.includedIPs=$included_ips/' /root/application.properties; sed -i 's/^spring.rabbitmq.host=.*/spring.rabbitmq.host=$RABBIT_MQ_HOST/' /root/application.properties; sed -i 's/^comm.minRemoteIP=.*/comm.minRemoteIP=$min_ip/' /root/application.properties; sed -i 's/^comm.maxRemoteIP=.*/comm.maxRemoteIP=$max_ip/' /root/application.properties"

  if [[ $host =~ ^(s)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    min_connections=4
    if [[ $AMOUNT_NODES -eq 25 ]]; then
      min_connections=5
    fi
    if [[ $AMOUNT_NODES -eq 50 ]]; then
      min_connections=6
    fi
    if [[ $AMOUNT_NODES -eq 100 ]]; then
      min_connections=7
    fi
    ssh -n -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.minConnections=.*/comm.minConnections=$min_connections/' /root/application.properties"
  fi

  if [[ $host =~ ^(m)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    min_connections=3
    if [[ $AMOUNT_NODES -eq 25 ]]; then
      min_connections=4
    fi
    if [[ $AMOUNT_NODES -eq 50 ]]; then
      min_connections=5
    fi
    if [[ $AMOUNT_NODES -eq 100 ]]; then
      min_connections=6
    fi
    ssh -n -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.minConnections=.*/comm.minConnections=$min_connections/' /root/application.properties"
  fi

  if [[ $host =~ ^(w)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    min_connections=2
    if [[ $AMOUNT_NODES -eq 25 ]]; then
      min_connections=3
    fi
    if [[ $AMOUNT_NODES -eq 50 ]]; then
      min_connections=4
    fi
    if [[ $AMOUNT_NODES -eq 100 ]]; then
      min_connections=5
    fi
    ssh -n -T -o StrictHostKeyChecking=no "$host" "sed -i 's/^comm.minConnections=.*/comm.minConnections=$min_connections/' /root/application.properties"
  fi
}

included_ips=$(collected_included_ips)
min_ip=$(calculate_min_ip "$included_ips")
max_ip=$(calculate_max_ip "$included_ips")
printf "Calculated \n\tincluded ips: %s\n\tmin ip: %s\n\tmax ip: %s\n" "$included_ips" "$min_ip" "$max_ip"

printf "\nRebooting nodes...\n"
reboot_nodes
printf "\nNodes rebooted\n"

printf "\nWaiting till nodes are online...\n"
wait_till_nodes_online

printf "\nShutdown firewalls...\n"
shutdown_firewalls
printf "\nFirewalls shutdown\n"

printf "\nSetting application properties...\n"
set_application_properties "$included_ips" "$min_ip" "$max_ip"
printf "\nApplication properties set\n"

printf "\n\n##### DONE #####\n"
