#!/bin/bash
source /root/stackrc
PREFIX=unicorn
PROJECT_OUTPUT=$(keystone tenant-list | grep $PREFIX )

PROJECT_LIST=""
for item in $PROJECT_OUTPUT;
do
   PROJECT_LIST="$PROJECT_LIST $(echo $item | grep $PREFIX)"
done

echo "Project List:"
echo $PROJECT_LIST

#for tenant in $PROJECT_LIST;
for i in `seq 30 40`;
do
    tenant=$PREFIX"_c"$i
    export OS_TENANT_NAME=$tenant
    i=$(echo $tenant | awk -F'[_c]' '{ print $4 }')
    echo "************* Processing project $tenant on Compute$i ****************"

    PREFIX_NETWORK_1=$PREFIX"_c"$i"_1"
    PREFIX_NETWORK_2=$PREFIX"_c"$i"_2"
    echo "Network 1: $PREFIX_NETWORK_1"
    echo "Network 2: $PREFIX_NETWORK_2"

    NETWORK_1_ID=$(openstack network list | grep $PREFIX_NETWORK_1 | awk '{ print $2 }')
    NETWORK_2_ID=$(openstack network list | grep $PREFIX_NETWORK_2 | awk '{ print $2 }')    
    echo Network IDs: 
    echo "   $NETWORK_1_ID"
    echo "   $NETWORK_2_ID"
    
    IP_SERVER=$(nova list | grep $i"_1_vm1" | awk -F'[=]' '{ print $2 }' | awk -F'[ ]' '{ print $1 }')
    IP_CLIENT=$(nova list | grep $i"_2_vm1" | awk -F'[=]' '{ print $2 }' | awk -F'[ ]' '{ print $1 }')
    echo "Server IP: $IP_SERVER"
    echo "Client IP: $IP_CLIENT"

    ssh-keygen -R $IP_SERVER
    ssh-keygen -R $IP_CLIENT


    # start netserver on port 6000
    echo "Starting netperf netserver on port 6000"
    ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER sudo netstat -punta | grep 6000
#    FLAG=$(ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER "netstat -punta | grep 6000 | wc -l")
#    if [ $FLAG -lt 1 ]; then
#       echo "    Netperf server not started on port 6000 on $IP_SERVER ****** FAILED"
#    else 
#       echo "    Netperf server started on port 6000 successfully...."
#    fi  

done

