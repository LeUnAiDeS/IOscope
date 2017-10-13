#!/usr/bin/python
#
#  report the number of the I/O waiting requests insid the scheduler.
#                   
#
# 
#
# Copyright 2017 Xilopix, Inc. 
# Author: Abdulqawi SAIF
# Licensed under the Apache License, Version 2.0 (the "License")

from __future__ import print_function
from bcc import BPF
import argparse
from time import sleep
import ctypes as ct
import subprocess
from subprocess import call

examples = """examples:
    ./NoopSchedTool.py                  # report waiting io requests
    ./NoopSchedTool.py -c    	          # clear the screen
    ./NoopSchedTool.py -i 0.5           # report the value each 0.5 sec
    ./NoopSchedTool.py -d sda           # tracing on the selected disk
    ./NoopSchedTool.py -c -i 2 -d sdb   # trace on the disk sdb, clear the sceen and outputs every 2 Secs
"""

parser = argparse.ArgumentParser(
    description="This script reports the number of I/O schedulers that are waiting at NOOP,\
 the reported information could help to determine how the analyzed system is issuing its I/O requests (the flow of the IO requests of a given system)",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-c", "--clearScreen",  action="store_true",
    help="Clear the screen after each output, default: not activated")
parser.add_argument("-i", "--interval", default=0.3,
    help="sleeping interval between each output, default: 0.3 Sec")
parser.add_argument("-d", "--disk", default="sda",
    help="target disk that should be monitored, default: sda")
args = parser.parse_args()  

interval = float(args.interval)
clear = int(args.clearScreen)


if "[noop]" not in subprocess.Popen("cat /sys/block/%s/queue/scheduler" %args.disk, shell=True, stdout=subprocess.PIPE).stdout.read():
   print ("You must use noop as a scheduler on your disk: %s" %args.disk)
   print ("Execute this: echo noop > /sys/block/%s/queue/scheduler" %args.disk)
   exit(0)


# load BPF program
mytext="""
#include <uapi/linux/ptrace.h>


struct info {
    char comm;
    u64 noReq;
};


BPF_PERF_OUTPUT(events);

int do_trace(struct pt_regs *ctx, long *q, char x) {

    struct info req = {};
    req.comm = x;
    req.noReq = *q; 
    
    events.perf_submit(ctx, &req, sizeof(req));
       
   return 0;
}
"""

# attaching the tracing code to the target function.
 

b = BPF(text=mytext)
b.attach_kprobe(event="noop_update_waiting_io", fn_name="do_trace")

print("Tracing in progress... Ctrl-C to end")


class Data(ct.Structure):
    _fields_ = [("comm", ct.c_char),
                 ("waitingReq", ct.c_ulonglong)]

def print_event(cpu, data, size):
  exiting=0
  event = ct.cast(data, ct.POINTER(Data)).contents
  if clear: 
     call("clear")
  print(event.waitingReq, event.comm)
  try: 
     sleep(interval)
  except KeyboardInterrupt:
      exiting=1
  if exiting:
       print()
       print("Detaching...")
       exit()

b["events"].open_perf_buffer(print_event, page_cnt=4096)

while 1: 
    b.kprobe_poll()

