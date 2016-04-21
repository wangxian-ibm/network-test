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

for tenant in $PROJECT_LIST;
do
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

    # Ping test to client and server
    echo "Ping test to server" 
    FLAG=$(ip netns exec qdhcp-$NETWORK_1_ID ping -c 3 $IP_SERVER | grep ", 0% packet loss" | wc -l)
    if [ $FLAG -lt 1 ]; then 
         echo "    ip netns exec qdhcp-$NETWORK_1_ID ping -c 3 $IP_SERVER ****** FAILED"
    fi   
    echo "Ping test to client" 
    FLAG=$(ip netns exec qdhcp-$NETWORK_2_ID ping -c 3 $IP_CLIENT |  grep ", 0% packet loss" | wc -l)
    if [ $FLAG -lt 1 ]; then
         echo "    ip netns exec qdhcp-$NETWORK_2_ID ping -c 3 $IP_CLIENT ****** FAILED"
    fi

    # SSH test to client and server
    echo "SSH test to server"
    echo "ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER echo $PREFIX"
    OUTPUT=$(ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER echo $PREFIX)
    if [ "$OUTPUT" != "$PREFIX" ]; then
        echo "    ssh $IP_SERVER on qdhcp-$NETWORK_1_ID ****** FAILED"
    else 
         # start netserver on port 6000
         echo "Starting netperf netserver on port 6000"
         ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER sudo netserver -p 6000
         FLAG=$(ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER "netstat -punta | grep 6000 | wc -l")
        if [ $FLAG -lt 1 ]; then
            echo "    Netperf server not started on port 6000 on $IP_SERVER ****** FAILED"
        else 
	    echo "    Netperf server started on port 6000 successfully...."
        fi  
    fi

    echo "SSH test to client"
    echo "ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT echo $PREFIX"
    OUTPUT=$(ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT echo $PREFIX)
    if [ "$OUTPUT" != "$PREFIX" ]; then
       echo "    ssh $IP_CLIENT on qdhcp-$NETWORK_2_ID ****** FAILED"
    fi 

    # ping from server to client
    echo "Ping test between server and client" 
    FLAG=$(ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER ping -c 3 $IP_CLIENT | grep ", 0% packet loss" | wc -l)
    if [ $FLAG -lt 1 ]; then
       echo "    $IP_SERVER could not ping $IP_CLIENT ****** FAILED"
    else 
       echo "    Pinged from server to client successfully...."  
    fi

#    ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER netstat -s | grep -E 'segments retransmited|packet receive errors' 
#    echo Client IP: $IP_CLIENT
#    ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netstat -s | grep -E 'segments retransmited|packet receive errors'
    
#    # ping from server to client
#    echo "ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER sudo netserver -p 6000"
#    ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER sudo netserver -p 6000 
#    ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netperf -H $IP_SERVER -p 6000 -l 15 -t UDP_STREAM -- -m 16384
#    echo "ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netperf -H $IP_SERVER -p 6000 -l 15 -t TCP_STREAM -- -m 16384"
#    ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netperf -H $IP_SERVER -p 6000 -l 15 -t TCP_STREAM -- -m 16384
#    ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netperf -H $IP_SERVER -p 6000 -l 15 -t TCP_RR -- -m 16384
# 
#    # collect data after
#    echo "Collect data after:"
#    echo Server IP: $IP_SERVER
#    ip netns exec qdhcp-$NETWORK_1_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_SERVER netstat -s | grep -E 'segments retransmited|packet receive errors'
#    echo Client IP: $IP_CLIENT
#    ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT netstat -s | grep -E 'segments retransmited|packet receive errors'
#

done

