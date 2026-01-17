#!/bin/bash

FNAME=`ls -1rt AL80_monitor_a000_UART*.bin | tail -n 1`
echo "Using ${FNAME}"

dd if=${FNAME} of=/dev/sdb bs=512 seek=1

