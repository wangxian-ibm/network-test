#!/bin/bash
PREFIX=unicorn

#verify that there are 0 projects/networks/vms before starting

#duplicate projects, subnets are fine (openstack wont allow). 
#Duplicate networks, routers = not fine. Must ensure everything  is deleted beforehand


#number of computes, verify greater than 1
#choose location this runs on, local/deployer/controller?
#Currently set up for controller

source ~/stackrc
NUM_COMPUTES=$(nova service-list | grep compute | wc -l)

for i in `seq 1 $NUM_COMPUTES`;
#for i in `seq 6 100`;
do
   echo Creating project $PREFIX"_c"$i
   openstack project create $PREFIX"_c"$i
   
   PROJECT_ID=$(openstack project list | grep $PREFIX"_c"$i | cut -d"|" -f2)
   openstack role add --user admin  --project $PROJECT_ID  admin
   export OS_TENANT_NAME=$PREFIX"_c"$i  
   
   #create security group 
   nova secgroup-create unlocked open
   nova secgroup-add-rule unlocked  tcp 1 65535 0.0.0.0/0
   nova secgroup-add-rule unlocked  udp 1 65535 0.0.0.0/0
   nova secgroup-add-rule unlocked  icmp -1 -1 0.0.0.0/0

   #For each project create 2 networks 
   echo "Creating network and subnet"
   openstack network create $PREFIX"_c"$i"_1" --project $PREFIX"_c"$i
   neutron subnet-create $PREFIX"_c"$i"_1" 123.$i".1.0/28" --name $PREFIX"_c"$i"_1"

   openstack network create $PREFIX"_c"$i"_2" --project $PREFIX"_c"$i
   neutron subnet-create $PREFIX"_c"$i"_2" 123.$i".2.0/28" --name $PREFIX"_c"$i"_2"

   #Route between the networks
   neutron router-create $PREFIX"_c"$i --tenant-id $PROJECT_ID
   neutron router-interface-add $PREFIX"_c"$i $PREFIX"_c"$i"_1"
   neutron router-interface-add $PREFIX"_c"$i $PREFIX"_c"$i"_2"
done
