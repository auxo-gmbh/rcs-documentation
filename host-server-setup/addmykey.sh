#!/bin/bash

key="$(cat ~/.ssh/dsg_gitlab.pub)"

user=root
user=ubnt

for h in $*
do
ssh $user@$h "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && if grep -xq '$key' ~/.ssh/authorized_keys ; then echo already included in $h; else echo '$key' >> ~/.ssh/authorized_keys && echo added to $h; fi" || echo "$h failed"
done
