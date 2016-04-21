#!/bin/bash
source /root/stackrc
PREFIX=unicorn
PROJECT_OUTPUT=$(keystone tenant-list | grep $PREFIX )

PROJECT_LIST=""
for item in $PROJECT_OUTPUT;
do
   PROJECT_LIST="$PROJECT_LIST $(echo $item | grep $PREFIX )"
done

echo "Project List:"
echo $PROJECT_LIST

for tenant in $PROJECT_LIST;
do
    echo "****************** Clean up tenant $tenant ************************"
    export OS_TENANT_NAME=$tenant

    #delete vms
    VM_ID_LIST=$(nova list | grep $PREFIX | awk '{ print $2 }')
    for item in $VM_ID_LIST
    do
      echo deleting vm $item 
      nova delete $item
      sleep 1
    done

    #delete security group
    #SECURITY_GROUP_ID_LIST=$(nova secgroup-list | grep "unlocked" | cut -d"|" -f2 | tr -d '[[:space:]]')
    SECURITY_GROUP_ID_LIST=$(nova secgroup-list | grep "unlocked" | awk '{ print $2 }') 
    for item in $SECURITY_GROUP_ID_LIST
    do
        echo deleting sec group $item
        nova secgroup-delete $item
    done

    openstack project delete $tenant
done


source /root/stackrc

#delete router
ROUTER_LIST=$(neutron router-list | grep unicorn | awk '{ print $4 }')
for router in $ROUTER_LIST
do
    # delete interfaces
    echo deleting router $router
    SUBNET_LIST=$(neutron subnet-list | grep $router | awk '{ print $2 }')
    for subnet in $SUBNET_LIST
    do
        echo detatching subnet $subnet from $router
        neutron router-interface-delete $router $subnet
    done
    neutron router-delete $router
    echo router $router deleted
done

#echo Deleting networks
NETWORK_LIST=$(openstack network list | cut -d'|' -f3 | grep unicorn)
for i in $NETWORK_LIST
do
    neutron net-delete $i
done


