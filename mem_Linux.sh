#########################################################################################################################
## This script was developed by Guberni and is part of Tellki monitoring solution                     		           ##
##                                                                                                      	           ##
## December, 2014                     	                                                                	           ##
##                                                                                                      	           ##
## Version 1.0                                                                                          	           ##
##																									    	           ##
## DESCRIPTION: Monitor memory utilization (swap and physical memory)											       ##
##																											           ##
## SYNTAX: ./mem_Linux.sh <METRIC_STATE>             														           ##
##																											           ##
## EXAMPLE: ./mem_Linux.sh "1,1,1,1,1,1,0,0"         														           ##
##																											 	       ##
##                                      ############                                                    	 	       ##
##                                      ## README ##                                                    	 	       ##
##                                      ############                                                    	 	       ##
##																											 	       ##
## This script is used combined with runremote.sh script, but you can use as standalone. 			    	 	       ##
##																											 	       ##
## runremote.sh - executes input script locally or at a remove server, depending on the LOCAL parameter.	 	       ##
##																											 	       ##
## SYNTAX: sh "runremote.sh" <HOST> <METRIC_STATE> <USER_NAME> <PASS_WORD> <TEMP_DIR> <SSH_KEY> <LOCAL> 	 	       ##
##																											       	   ##
## EXAMPLE: (LOCAL)  sh "runremote.sh" "mem_Linux.sh" "192.168.1.1" "1,1,1,1,1,1,1,1" "" "" "" "" "1"              	   ##
## 			(REMOTE) sh "runremote.sh" "mem_Linux.sh" "192.168.1.1" "1,1,1,1,1,0,0,0" "user" "pass" "/tmp" "null" "0"  ##
##																											 	   	   ##
## HOST - hostname or ip address where script will be executed.                                         	 	   	   ##
## METRIC_STATE - is generated internally by Tellki and its only used by Tellki default monitors.       	 	   	   ##
##         		  1 - metric is on ; 0 - metric is off					              						 	   	   ##
## USER_NAME - user name required to connect to remote host. Empty ("") for local monitoring.           	 	   	   ##
## PASS_WORD - password required to connect to remote host. Empty ("") for local monitoring.            	 	   	   ##
## TEMP_DIR - (remote monitoring only): directory on remote host to copy scripts before being executed.		 	   	   ##
## SSH_KEY - private ssh key to connect to remote host. Empty ("null") if password is used.                 	 	   ##
## LOCAL - 1: local monitoring / 0: remote monitoring                                                   	 	   	   ##
#########################################################################################################################


#METRIC_ID
mfree="66:Free Physical Memory:4"
mcache="4:Memory Cached:4"
mpct="82:% Used Physical Memory:6"
sused="15:Used Swap:4"
sfree="47:Free Swap:4"
spct="16:% Used Swap:6"
sin="142:Swap In per Second:4"
sout="13:Swap Out per Second:4"

#INPUTS
mfree_on=`echo $1 | awk -F',' '{print $1}'`
mcache_on=`echo $1 | awk -F',' '{print $2}'`
mpct_on=`echo $1 | awk -F',' '{print $3}'`
sused_on=`echo $1 | awk -F',' '{print $6}'`
sfree_on=`echo $1 | awk -F',' '{print $4}'`
spct_on=`echo $1 | awk -F',' '{print $5}'`
swapin_on=`echo $1 | awk -F',' '{print $7}'`
swapout_on=`echo $1 | awk -F',' '{print $8}'`

vmstat_out=`vmstat 1 3 | tail -1`

if [ $mfree_on -eq 1 ]
then
	memfree=`free | grep Mem | awk '{print int($4/1024)}'`
	if [ "$memfree" = "" ]
	then
		#Unable to collect metrics
		exit 8
	fi
fi
if [ $mcache_on -eq 1 ] || [ $mpct_on -eq 1 ]
then
	memtotal=`free | grep Mem | awk '{print int($2/1024)}'`
	memused=`free | grep Mem | awk '{print int($3/1024)}'`
	
	havebuffcache=`free | grep buff/cache | wc -l`
	if [ $havebuffcache -eq 0 ]
	then
		memcache=`free | grep Mem | awk '{print int($7/1024)}'`
		membuffers=`free | grep Mem | awk '{print int($6/1024)}'`
	else
		memcache=`free -w | grep Mem | awk '{print int($7/1024)}'`
		membuffers="0"
	fi

	havebuffers=`free | grep cache: | wc -l`
	if [ $havebuffers -eq 0 ]
	then
		memUsedPct=$(($memused*100/$memtotal))
	else
		memUsedPct=$((($memused-$membuffers-$memcache)*100/$memtotal))
	fi
	
	if [ $mcache_on -eq 1 ]
	then
		if [ "$memcache" = "" ]
		then
			#Unable to collect metrics
			exit 8
		fi
	fi
	if [ $mpct_on -eq 1 ]
	then
		if [ "$memUsedPct" = "" ]
		then
			#Unable to collect metrics
			exit 8
		fi
	fi
fi
if [ $spct_on -eq 1 ] || [ $sused_on -eq 1 ]
then
	swaptotal=`free | grep Swap | awk '{print int($2/1024)}'`
	swapused=`free | grep Swap | awk '{print int($3/1024)}'`
	if [ $swaptotal -eq 0 ]
	then
		swapusedpct="0"
	else
		swapusedpct=$((($swapused*100)/$swaptotal))
	fi
	if [ $sused_on -eq 1 ]
	then
		if [ "$swapused" = "" ]
		then
			#Unable to collect metrics
			exit 8 
		fi
	fi
	if [ $spct_on -eq 1 ]
	then
		if [ "$swapusedpct" = "" ]
		then
			#Unable to collect metrics
			exit 8 
		fi
	fi
fi
if [ $sfree_on -eq 1 ]
then
	swapfree=`free | grep Swap | awk '{print int($4/1024)}'`
	if [ "$swapfree" = "" ]
	then
		#Unable to collect metrics
		exit 8 
	fi
fi
if [ $swapin_on -eq 1 ]
	then
		swapin=`echo $vmstat_out | awk '{print int($7/1024)}'`
		if [ "$swapin" = "" ]
		then
			#Unable to collect metrics
			exit 8 
		fi
fi
	if [ $swapout_on -eq 1 ]
	then
		swapout=`echo $vmstat_out | awk '{print int($8/1024)}'`
		if [ "$swapout" = "" ]
		then
			#Unable to collect metrics
			exit 8 
		fi
	fi

# Send Metrics
if [ $mfree_on -eq 1 ]
then
	echo "$mfree|$memfree|"
fi
if [ $mcache_on -eq 1 ]
then
	echo "$mcache|$memcache|"
fi
if [ $mpct_on -eq 1 ]
then
	echo "$mpct|$memUsedPct|"
fi
if [ $sused_on -eq 1 ]
then
	echo "$sused|$swapused|"
fi
if [ $spct_on -eq 1 ]
then
	echo "$spct|$swapusedpct|"
fi
if [ $sfree_on -eq 1 ]
then
	echo "$sfree|$swapfree|"
fi
if [ $swapin_on -eq 1 ]
then
	echo "$sin|$swapin|"
fi
if [ $swapout_on -eq 1 ]
then
	echo "$sout|$swapout|"
fi
