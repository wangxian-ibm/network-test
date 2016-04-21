#!/bin/bash

VXLAN_LIST=$(ip a | grep vxlan | awk '{print $2}')

for VXLAN in $VXLAN_LIST
do
    bridge fdb add 00:00:00:00:00:00 dev $VXLAN dst 10.130.101.139 self permanent
    bridge fdb append 00:00:00:00:00:00 dev $VXLAN dst 10.130.101.139 self permanent
    bridge fdb append 00:00:00:00:00:00 dev $VXLAN dst 10.130.101.138 self permanent
done
