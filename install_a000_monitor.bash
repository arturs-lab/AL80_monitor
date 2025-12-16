#!/bin/bash

FNAME=AL80_monitor_a000_UART_0C3911.bin

dd if=${FNAME} of=/dev/sdb bs=512 seek=1

