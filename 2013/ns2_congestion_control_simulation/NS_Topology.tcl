#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Red
$ns color 2 Blue

#Open the trace files outX.tr for Xgraph and out.nam for nam
set f0 [open out_tcp0.tr w]
set f1 [open out_tcp1.tr w]

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
 global ns nf f0 f1
 $ns flush-trace
#Close the NAM trace file
 close $nf
#Close the output files
 close $f0
 close $f1
#Execute xgraph to display the results
 exec xgraph out_tcp0.tr out_tcp1.tr -geometry 600x400 &
#Execute NAM on the trace file
 exec nam out.nam &
 exit 0
}

#Create five nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]

#Create links between the nodes
$ns duplex-link $n0 $n1 100Mb 1ms DropTail
$ns duplex-link $n1 $n2 5Mb 35ms DropTail
$ns duplex-link $n2 $n4 100Mb 1ms DropTail
$ns duplex-link $n3 $n2 100Mb 20ms DropTail

#record procedure
proc record {} {
 global sink sink1 f0 f1
#Get an instance of the simulator
 set ns [Simulator instance]

#Set the time after which the procedure should be called again
 set time 0.5

#How many bytes have been received by the traffic sinks?
 set bw0 [$sink set bytes_]
 set bw1 [$sink1 set bytes_]

#Get the current time
 set now [$ns now]

#Calculate the bandwidth (in MBit/s) and write it to the files
 puts $f0 "$now [expr $bw0/$time*8/1000000]"
 puts $f1 "$now [expr $bw1/$time*8/1000000]"

#Reset the bytes_ values on the traffic sinks
 $sink set bytes_ 0
 $sink1 set bytes_ 0

#Re-schedule the procedure
 $ns at [expr $now+$time] "record"
}

#Setup a TCP connection
set tcp [new Agent/TCP/Linux]
$tcp set class_ 2
$ns at 0 "$tcp select_ca westwood_new"
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Setup a TCP connection
set tcp1 [new Agent/TCP/Linux]
$tcp1 set class_ 2
$ns at 0 "$tcp select_ca westwood_new"
$ns attach-agent $n3 $tcp1
set sink1 [new Agent/TCPSink]
$ns attach-agent $n4 $sink1
$ns connect $tcp1 $sink1
$tcp1 set fid_ 2

#Setup a FTP over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP

#Start logging the received bandwidth
$ns at 0.0 "record"

#Schedule events for the FTP agents
$ns at 0.1 "$ftp start"
$ns at 0.8 "$ftp1 start"
$ns at 140.0 "$ftp1 stop"
$ns at 140.0 "$ftp stop"

#Call the finish procedure after 5 seconds of simulation time
$ns at 140.0 "finish"

#Run the simulation
$ns run
