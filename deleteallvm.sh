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
    done
done


