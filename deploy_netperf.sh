netperftest() {

    # collect data before
    echo "Collect packet data before test..."
    echo "Packet data before" > ~/$2
    netstat -s | grep -E 'segments retransmited|packet receive errors' >>  ~/$2
    echo "----------------" >> ~/$2

    echo beginning netperf test $1    
    netperf -H REPLACE_SERVER -p 6000 -l 600 -t $1 -- -m 16384 $3>> ~/$2
    #Wait for previous process to finish
    wait $!
    echo "----------------" >> ~/$2
    echo netperf process has completed
    
    
    # collect data after
    echo collect packet data after test... 
    echo "Packet data before" >> ~/$2
    netstat -s | grep -E 'segments retransmited|packet receive errors' >>  ~/$2
    echo "----------------" >> ~/$2
}

netperftest REPLACE_INPUT

#netperftest TCP_STREAM netperftcp.txt
#netperftest UDP_STREAM netperfudp.txt "-R 1"
#netperftest TCP_RR netperftcprr.txt
