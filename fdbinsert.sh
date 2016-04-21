update_kernel_params() {
     scp deploy_fdbinsert.sh $1:~/fdbinsert.sh
     echo Adding FDB params  $1
     ssh $1 bash -c ~/fdbinsert.sh

}

update_kernel_params controller1
update_kernel_params controller2
for i in `seq 1 100`;
do
    update_kernel_params compute$i
done