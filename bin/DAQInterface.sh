#!/bin/bash

if [[ -n $1 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	. $ARTDAQ_DAQINTERFACE_DIR/bin/help.sh
	exit 0
    else
       echo "Unknown option passed to DAQInterface!"
       exit 1
    fi 
fi


# In the code below:
# -The "nohup" is there so DAQInterface can wind down cleanly if users close its terminal
# -The "stdbuf -oL" is there so that DAQInterface output makes it into the logfile in realtime
# -The "<&-" is there to avoid hangs if users type in the terminal DAQInterface is running in (see Issue #21804)

# Make sure the logic to derive DAQInterface port # from partition #
# is the same as in daqinterface_functions.sh!

export DAQINTERFACE_PORT=$(( $ARTDAQ_BASE_PORT + $DAQINTERFACE_PARTITION_NUMBER * $ARTDAQ_PORTS_PER_PARTITION ))

expanded_daqinterface_logfilename=$( echo $( eval echo $DAQINTERFACE_LOGFILE ) )
echo [DAQInterface.sh:$LINENO] : \$DAQINTERFACE_LOGFILE=$DAQINTERFACE_LOGFILE
if [[ ! -e $expanded_daqinterface_logfilename ]]; then
    > $expanded_daqinterface_logfilename  # Create the logfile so tail -f, below, won't complain
fi


if [[ -z $( ps aux | grep "$DAQINTERFACE_TTY.*tail -n0 -f $expanded_daqinterface_logfilename" | grep -v grep ) ]]; then

    tail -n0 -f $expanded_daqinterface_logfilename &

fi

nohup stdbuf -oL $ARTDAQ_DAQINTERFACE_DIR/rc/control/daqinterface.py --partition-number $DAQINTERFACE_PARTITION_NUMBER --rpc-port $DAQINTERFACE_PORT <&- >> $expanded_daqinterface_logfilename 2>&1 

pid=$( ps aux | grep "$DAQINTERFACE_TTY.*tail -n0 -f $expanded_daqinterface_logfilename" | grep -v grep | awk '{print $2}' )

if [[ -n $pid ]]; then
    kill $pid
fi

unset pid
unset expanded_daqinterface_logfilename
