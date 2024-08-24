#!/bin/bash

# !!!!!!!!!!!!!!!!!!!
# TODO CHANGE BEFORE RUN
readonly ALGORITHM_PROFILE="Gossips"
readonly NODES_FILE=nodes-100
# !!!!!!!!!!!!!!!!!!

readonly S_FAIL_PROB=10
readonly M_FAIL_PROB=20
readonly W_FAIL_PROB=30

readonly S_REBOOT_PROB=40
readonly M_REBOOT_PROB=30
readonly W_REBOOT_PROB=20

SECONDS=0

failed_nodes=()

nodes=()
while IFS= read -r node; do
  nodes+=("$node")
done <$NODES_FILE

calculate_node_failure_prob() {
  local host=$1
  local random_number
  random_number=$(shuf -i 0-100 -n 1)

  if [[ $host =~ ^(s)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$S_FAIL_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi

  if [[ $host =~ ^(m)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$M_FAIL_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi

  if [[ $host =~ ^(w)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$W_FAIL_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi
}

terminate_node() {
  local host=$1
  local random_number=$2

  ssh -n -T -o StrictHostKeyChecking=no "$host" "list=\$(ps -ef | pgrep -f '^(timeout|java)'); while IFS= read -r line ; do kill -9 \$line ; done <<< \"\$list\"" && printf "%s failed with %s in simulation.\n" "$host" "$random_number"
}

calculate_node_reboot_prob() {
  local host=$1
  local random_number
  random_number=$(shuf -i 0-100 -n 1)

  if [[ $host =~ ^(s)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$S_REBOOT_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi

  if [[ $host =~ ^(m)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$M_REBOOT_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi

  if [[ $host =~ ^(w)[1-9][0-9]?-[1-9][0-9]?$ ]]; then
    if [ "$random_number" -le "$W_REBOOT_PROB" ]; then
      printf "%s" "$random_number"
      return
    fi
  fi
}

reboot_node() {
  local host=$1
  local random_number=$2
  local seconds_passed=$SECONDS
  local remaining_minutes="$((60 - (seconds_passed / 60)))"

  ssh -T -o StrictHostKeyChecking=no "$host" "timeout ${remaining_minutes}m  java -Dspring.profiles.active=$ALGORITHM_PROFILE,remote -jar rain-cloud-system-1.0.0-exec.jar --spring.config.location=application.properties &>/dev/null &"

  failed_nodes=("${failed_nodes[@]/$host/}")

  printf "%s recovered with %s in simulation. Will be rebooted and run for %s minutes\n" "$host" "$random_number" "$remaining_minutes"
}

shopt -s nocasematch

minutes_passed=0

while true; do
  for host in "${nodes[@]}"; do
    if (("$minutes_passed" != 0 && "$minutes_passed" % 15 == 0)); then
      should_stop=$(calculate_node_failure_prob "$host")
      if [ "$should_stop" ]; then
        failed_nodes+=("$host")
        terminate_node "$host" "$should_stop"
      fi
    fi
  done

  for node in "${failed_nodes[@]}"; do
    should_reboot=$(calculate_node_reboot_prob "$node")
    if [ "$should_reboot" ]; then
      reboot_node "$node" "$should_reboot"
    fi
  done

  sleep 60
  minutes_passed=$((SECONDS / 60))
  printf "minutes passed %s\n" "$minutes_passed"

  if [ "$minutes_passed" -ge 60 ]; then
    exit
  fi
done
