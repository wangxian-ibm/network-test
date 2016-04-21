#!/bin/bash

graphme () {
        echo $4 > $1

        for i in `seq 1 100`;
        do
           echo -n  "unicorn_c$i, " >> $1
           DATA_FILE="$2"_unicorn_c"$i".txt

           TRANSMIT_PACKET=$(cat $DATA_FILE | grep retransmited | awk '{ print $1 }')
           for X in $TRANSMIT_PACKET
           do
              echo -n  "$X, " >> $1
           done

           ERROR_PACKET=$(cat $DATA_FILE | grep "receive errors" | awk '{ print $1 }')
           for X in $ERROR_PACKET
           do
              echo -n  "$X, " >> $1
           done


           NETPERF=$(sed -n "$3"p $DATA_FILE)
           for X in $NETPERF
           do
              echo -n "$X, " >> $1
           done

           echo "" >> $1
        done
}
TCP_STREAM_HEAD="comp_node, s_transmit, e_transmit, s_error, e_error, rcv_socket, send_socket, send_msg, elapse_time, throughput"
UDP_STREAM_HEAD="comp_node, s_transmit, e_transmit, s_error, e_error, socket_size, msg_size, elapsed_time, msg_ok, msg_err, throughput"
TCP_RR_HEAD="comp_node, s_transmit, e_transmit, s_error, e_error, socket_send, socket_rcv, req_size, rsp_size, time, throughput"
graphme tcp_stream.txt TCP_STREAM 11 \""$TCP_STREAM_HEAD\""
graphme udp_stream.txt UDP_STREAM 10 \""$UDP_STREAM_HEAD\""
graphme tcp_rr.txt TCP_RR 11 \""$TCP_RR_HEAD\""