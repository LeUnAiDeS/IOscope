#!/usr/bin/python
#
# Tracing and reporting the I/O access patterns of any workload that passes through VFS layer. Hence, 
# this tool could catch any worklaod issued by all the variations of read & write system calls .
#
#
# Copyright 2017 Xilopix, Inc. 
# Author: Abdulqawi SAIF
# Licensed under the Apache License, Version 2.0 (the "License")

from __future__ import print_function
from bcc import BPF
import argparse
import signal
import re
import ctypes as ct

examples = """examples:
    ./IOscope_classic        # trace all the I/O worklaods of all I/O processes.             
    ./IOscope_classic -p 181    # trace a given I/O process (here process no 181), filtered and printed its different workloads to separate files
    ./IOscope_classic -p 181  -w 0  # trace only the read workloads of the given process 
   ./IOscope_classic -p 181  -w 1  # trace only the write workloads of the given process 
    ./IOscope_classic -p 181  -w 2  # trace only mixed worklaods (read and write) of the given process  
"""

parser = argparse.ArgumentParser(
    description="Tracing and reporting the IO requests sent to disk via pread function, \
it reports the requests filtered by file",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-p", "--pid", help="trace this PID only")
parser.add_argument("-w", "--workload", type = int, default= 0, help="trace the read, write, or both I/O activities")
arguments = parser.parse_args() 



#if not arguments.pid:
#   print("You must indicate the PID pf the target process to be traced, otherwise there are a lot of output, including the workloads on the system files")
#   exit(0)

# load BPF program
mytext = """
#include <uapi/linux/ptrace.h>
#include <linux/fs.h>
#include <linux/sched.h>
#include <linux/dcache.h>

struct reqInfo {
    char fileHandler[DNAME_INLINE_LEN];
    u64 offset; 
    u64 readByte;
    u64 timestamp;
    u64 latency_ms;
    u64 type;  // read 0 , write 1
};



BPF_HASH(token, u32, struct reqInfo);
BPF_HASH(token1, u32, struct reqInfo);
BPF_PERF_OUTPUT(events); 

int check_starting(struct pt_regs *ctx, struct file *f, char __user *buf, size_t count, loff_t *pos) {
    u32 pid = bpf_get_current_pid_tgid() >> 32; 
    FILTER
    struct reqInfo requestInfo = {};
    requestInfo.timestamp = bpf_ktime_get_ns();
    requestInfo.type =0;
    u64  offset=0, bytes=0; 

   // to take the fileName
    bpf_probe_read(&requestInfo.fileHandler,sizeof(requestInfo.fileHandler),(void *)f->f_path.dentry->d_name.name);
    requestInfo.readByte = count; 
    requestInfo.offset = *pos;
    token.update(&pid,&requestInfo);

//events.perf_submit(ctx, &requestInfo, sizeof(requestInfo));
    return 0;
}

int check_end(struct pt_regs *ctx) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    FILTER
    u64 ts = bpf_ktime_get_ns();
    struct reqInfo  *ref;
    ref = token.lookup(&pid);
    
    if(ref == 0) {
          // Oups, we missed this trace
       return 0;
     }
    
    ref->latency_ms = (ts-ref->timestamp) /1000000;  // from ns to ms
    //prepare data to be reported
    struct reqInfo data = {.timestamp = ts, .readByte =ref->readByte, .offset = ref->offset, .latency_ms= ref->latency_ms, .type = ref->type};
    bpf_probe_read(&data.fileHandler,sizeof(data.fileHandler),ref->fileHandler);
    token.delete(&pid);
    events.perf_submit(ctx, &data, sizeof(data));
    return 0; 
}


int writing_start(struct pt_regs *ctx, struct file *f, char __user *buf, size_t count, loff_t *pos) {

    u32 pid = bpf_get_current_pid_tgid() >> 32; 
    FILTER
    struct reqInfo requestInfo = {};
    requestInfo.timestamp = bpf_ktime_get_ns();
    requestInfo.type =1;
    u64  offset=0, bytes=0; 
   // to take the fileName
    bpf_probe_read(&requestInfo.fileHandler,sizeof(requestInfo.fileHandler),(void *)f->f_path.dentry->d_name.name);
    requestInfo.readByte = count; 
    requestInfo.offset = *pos;
    token1.update(&pid,&requestInfo);

//events.perf_submit(ctx, &requestInfo, sizeof(requestInfo));
    return 0;
}

int writing_end(struct pt_regs *ctx) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    FILTER
    u64 ts = bpf_ktime_get_ns();
    struct reqInfo  *ref;
    ref = token1.lookup(&pid);
    if(ref == 0) {
          // Oups, we missed this trace
       return 0;
     }
    ref->latency_ms = (ts-ref->timestamp) /1000000;  // from ns to ms
    //prepare data to be reported
    struct reqInfo data = {.timestamp = ts, .readByte =ref->readByte, .offset = ref->offset, .latency_ms= ref->latency_ms, .type = ref->type};
    bpf_probe_read(&data.fileHandler,sizeof(data.fileHandler),ref->fileHandler);
    token1.delete(&pid);
    events.perf_submit(ctx, &data, sizeof(data));
    return 0; 
}

"""
# attaching our tracing code to the target functions
 
if arguments.pid:
    mytext = mytext.replace('FILTER',
        'if (pid != %s) { return 0; }' % arguments.pid)
else:
    mytext= mytext.replace('FILTER', '')

b = BPF(text=mytext)

if arguments.workload==0:
  b.attach_kprobe(event="vfs_read", fn_name="check_starting")
  b.attach_kretprobe(event="vfs_read", fn_name="check_end")
elif arguments.workload==1: 
  b.attach_kprobe(event="vfs_write", fn_name="writing_start")
  b.attach_kretprobe(event="vfs_write", fn_name="writing_end")
else: 
  b.attach_kprobe(event="vfs_read", fn_name="check_starting")
  b.attach_kretprobe(event="vfs_read", fn_name="check_end")
  b.attach_kprobe(event="vfs_write", fn_name="writing_start")
  b.attach_kretprobe(event="vfs_write", fn_name="writing_end")


myFiles = []
indexes = []
print("Tracing in progress... Ctrl-C to end")


# manipulate the received events and do the post-filtering of the events into different files

DNAME_INLINE_LEN = 32;

class Data(ct.Structure):
    _fields_ = [("filename", ct.c_char * DNAME_INLINE_LEN), 
                ("offset", ct.c_ulonglong), 
                ("bytes", ct.c_ulonglong),
                ("timestamp", ct.c_ulonglong),
                ("latency", ct.c_ulonglong),
                ("type", ct.c_ulonglong) ]

def print_event(cpu, data, size):
  event = ct.cast(data, ct.POINTER(Data)).contents
  if event.filename not in indexes:
     myFiles.append(open('%s'%event.filename,'a'))
     indexes.append(event.filename)
     TempIndex = indexes.index(event.filename)
     myFiles[TempIndex].write("offset readByteSize  latency_ms  type  timestamp   \n")
 
  Index = indexes.index(event.filename)
  myFiles[Index].write("%d   %5d  %5.2f  %5d  %5.2f\n"%(event.offset, event.bytes, float(event.latency), event.type, event.timestamp))


b["events"].open_perf_buffer(print_event, page_cnt=8192)

while 1: 
  try: 
    b.kprobe_poll()
  except KeyboardInterrupt:
    print()
    print("Detaching...")
    exit()

