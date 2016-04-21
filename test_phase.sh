#!/bin/bash
source /root/stackrc

# set up vars
PREFIX=unicorn
FOLDER=$1
if [ -z "$FOLDER" ]; then
    FOLDER="."
fi

nova list --all-tenants > $FOLDER/nova-list.txt
openstack network list > $FOLDER/network-list.txt
echo "" > $FOLDER/server-list.txt

#Record the top process for controller1 and controller2
ssh 10.130.101.138  -n "top -d 4 -b -o USER | grep -ve root" > $FOLDER/controller1.netperf.top &
TOPC1=$!
ssh 10.130.101.139  -n "top -d 4 -b -o USER | grep -ve root" > $FOLDER/controller2.netperf.top &
TOPC2=$!

runtest() {

echo "" > $FOLDER/server-list.txt
for i in `seq 1 100`;
do
    tenant=$PREFIX"_c"$i
    echo "************* Processing project $tenant on compute$i***************"
    i=$(echo $tenant | awk -F'[_c]' '{ print $4 }')

    PREFIX_NETWORK_1=$PREFIX"_c"$i"_1"
    PREFIX_NETWORK_2=$PREFIX"_c"$i"_2"
    echo Network 1: $PREFIX_NETWORK_1
    echo Network 2: $PREFIX_NETWORK_2

    NETWORK_1_ID=$(cat $FOLDER/network-list.txt | grep $PREFIX_NETWORK_1 | awk '{ print $2 }')
    NETWORK_2_ID=$(cat $FOLDER/network-list.txt | grep $PREFIX_NETWORK_2 | awk '{ print $2 }')    
    echo Network IDs: 
    echo "   $NETWORK_1_ID"
    echo "   $NETWORK_2_ID"

    IP_SERVER=$(cat $FOLDER/nova-list.txt | grep " "$i"_1_vm1" | awk -F'[=]' '{ print $2 }' | awk -F'[ ]' '{ print $1 }')
    IP_CLIENT=$(cat $FOLDER/nova-list.txt | grep " "$i"_2_vm1" | awk -F'[=]' '{ print $2 }' | awk -F'[ ]' '{ print $1 }')
    echo "cat $FOLDER/nova-list.txt | grep " "$i"_1_vm1" | awk -F'[=]' '{ print $2 }' | awk -F'[ ]' '{ print $1 }'"
    echo ip_server $IP_SERVER
    echo ip_client $IP_CLIENT
    ssh-keygen -R $IP_SERVER
    ssh-keygen -R $IP_CLIENT

    # compile filename
    FILENAME=$1"_"$tenant".txt"
    echo "ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' scp -o StrictHostKeyChecking=no -o ConnectTimeout=3 ibmcloud@$IP_CLIENT:/home/ibmcloud/$2 $FOLDER/$FILENAME;" >> $FOLDER/server-list.txt

    # run netperf tests
    INPUT=$1" "$2" \""$3"\""
    echo "cat deploy_netperf.sh | sed "s/REPLACE_SERVER/$IP_SERVER/g" | sed "s/REPLACE_INPUT/$INPUT/g" | ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3  ibmcloud@$IP_CLIENT &"

    cat deploy_netperf.sh | sed "s/REPLACE_SERVER/$IP_SERVER/g" | sed "s/REPLACE_INPUT/$INPUT/g" | ip netns exec qdhcp-$NETWORK_2_ID sshpass -p 'Sm4rtcl0ud!' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3  ibmcloud@$IP_CLIENT &
 
done
}


echo "Running TCP_STREAM test..."
runtest TCP_STREAM netperftcp.txt

NUM=$(ps aux | grep "sshpass" | wc -l)
while [ $NUM -gt 1 ]
do
    NUM=$(ps aux | grep "sshpass" | wc -l)
    echo "Process: $NUM"
    sleep 2
done

echo "Copy files for TCP_STREAM..."
CMD=$(cat $FOLDER/server-list.txt)
echo "$CMD"
eval $CMD

echo "Running UDP_STREAM test..."
runtest UDP_STREAM netperfudp.txt "-R 1"

NUM=$(ps aux | grep "sshpass" | wc -l)
while [ $NUM -gt 1 ]
do
    NUM=$(ps aux | grep "sshpass" | wc -l)
    echo "Process: $NUM"
    sleep 2
done

echo "Copy files for UDP_STREAM..."
CMD=$(cat $FOLDER/server-list.txt)
echo "$CMD"
eval $CMD

echo "Running TCP_RR test..."
runtest TCP_RR netperftcprr.txt

NUM=$(ps aux | grep "sshpass" | wc -l)
while [ $NUM -gt 1 ]
do
    NUM=$(ps aux | grep "sshpass" | wc -l)
    echo "Process: $NUM"
    sleep 2
done

echo "Copy files for TCP_RR..."
CMD=$(cat $FOLDER/server-list.txt)
echo "$CMD"
eval $CMD

#Kill top process
kill -9 $TOPC1
kill -9 $TOPC2


rm -f $FOLDER/nova-list.txt
rm -f $FOLDER/network-list.txt
rm -f $FOLDER/server-list.txt
