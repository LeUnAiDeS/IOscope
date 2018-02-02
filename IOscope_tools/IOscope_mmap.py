#!/usr/bin/python
#
# Generating ready-to-draw access patterns for a given file.
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
import commands

# signal handler
def signal_ignore(signal, frame):
    print()

examples = """examples:
    ./IOscope_mmap           # trace every event that passes through our target function
    ./IOscope_mmap -i 181    # trace a given file by providing its inode number 
    ./IOscope_mmap -p /tmp/data/  -e "fdt"    # trace all the files with a given extention, located in all subfolders of the given path
"""

parser = argparse.ArgumentParser(
    description="Tracing and reporting the IO requests of a given file mapped into memory, \
the results also report the latency of each requests",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-i", "--inode",
    help="trace this inode demand paging only")
parser.add_argument("-p", "--path",
    help="give a path where the target files are located")
parser.add_argument("-e", "--extention",
    help="indicates which extention of files that you want to trace")

args = parser.parse_args() 


# load BPF program
mytext = """
#include <uapi/linux/ptrace.h>
#include <linux/fs.h>
#include <linux/sched.h>
#include <linux/dcache.h>
#include <linux/mm.h>
#include <linux/mm_types.h>
#include <linux/pagemap.h>


struct reqInfo {
    char fileHandler[DNAME_INLINE_LEN];
    u64 offset; 
    u64 offset1; // Offset (within vm_file) in PAGE_SIZE. first page of the region
    u64 address;
    u64 timestamp;
    u64 latencyMS;
};

BPF_HASH(token, u32, struct reqInfo);
BPF_PERF_OUTPUT(events); 


int check_starting(struct pt_regs *ctx, struct vm_area_struct *vma, struct vm_fault *vmf) {
   
   struct file *file = vma->vm_file;
   struct inode *target_inode =  file->f_mapping->host;
    u32 key = 1;
    u32 inode = target_inode-> i_ino;
    FILTER
    struct reqInfo requestInfo = {};

    requestInfo.timestamp = bpf_ktime_get_ns();  
   
    u64  offset=0, offset1=0;

  
   // to take the fileName
    bpf_probe_read(&requestInfo.fileHandler,sizeof(requestInfo.fileHandler),(void *)file->f_path.dentry->d_name.name);
    requestInfo.offset = vmf->pgoff;
    requestInfo.offset1 = vma->vm_pgoff;
    //bpf_probe_read(&requestInfo.address,sizeof(requestInfo.address),(void *)vmf->virtual_address);
    requestInfo.address = vmf->virtual_address; 
   
     token.update(&key,&requestInfo);

//   events.perf_submit(ctx, &requestInfo, sizeof(requestInfo));

    return 0;
}

int check_end(struct pt_regs *ctx) {
    
    u64 ts = bpf_ktime_get_ns();
    u32 key = 1; 
    struct reqInfo  *ref;
    ref = token.lookup(&key);
    
    if(ref == 0) {
          // Oups, we missed this trace
       return 0;
     }
    
    ref->latencyMS = (ts-ref->timestamp) /1000000;  // from ns to ms
   
    //prepare data to be reported
    struct reqInfo data = {.timestamp = ts, .address =ref->address, .offset = ref->offset, .offset1=ref->offset1, .latencyMS= ref->latencyMS};
    bpf_probe_read(&data.fileHandler,sizeof(data.fileHandler),ref->fileHandler);

    token.delete(&key);
     
    events.perf_submit(ctx, &data, sizeof(data));
    return 0; 
}
"""
# attaching our tracing code to the target function
 
if args.inode:
    mytext = mytext.replace('FILTER',
        'if (inode != %s) { return 0; }' % args.inode)
elif args.path:
  if args.extention: 
     command = "find %s -type f -name '*.%s' | xargs -n 2 ls -i  | cut -d ' ' -f 1"%(args.path,args.extention)
     s,v = commands.getstatusoutput(command)
     inodes=v.splitlines()  # list of inodes of the given extention  
     # make a conditional statement to replace filter
     replacement = "if ("
     for i in inodes:
         replacement+=("inode != "+ i + " ||")
     replacement = replacement[:-3]	
     replacement += "false) { return 0; }"
     mytext = mytext.replace('FILTER', replacement)
     print(mytext)
else:
    mytext= mytext.replace('FILTER', '')


b = BPF(text=mytext)
b.attach_kprobe(event="filemap_fault", fn_name="check_starting")
b.attach_kretprobe(event="filemap_fault", fn_name="check_end")


myFiles = []
indexes = []
print("Tracing in progress... Ctrl-C to end")

# post filtering mission 

DNAME_INLINE_LEN = 32;
class Data(ct.Structure):
    _fields_ = [("filename", ct.c_char * DNAME_INLINE_LEN), 
                ("offset", ct.c_ulonglong),
	         ("offset1", ct.c_ulonglong),
                ("address", ct.c_ulonglong),
                ("timestamp", ct.c_ulonglong), 
                 ("latency_ms", ct.c_ulonglong)]

def print_event(cpu, data, size):
  event = ct.cast(data, ct.POINTER(Data)).contents
  if event.filename not in indexes:
     myFiles.append(open('%s'%event.filename,'a'))
     indexes.append(event.filename)
     TempIndex = indexes.index(event.filename)
     #myFiles[TempIndex].write("filename   pagefaultOffset_word firstPageIndexInTheRegion  address latency_ms    timestamp\n")
     myFiles[TempIndex].write("filename   offset firstPageIndexInTheRegion  address latency_ms    timestamp\n")
     
  Index = indexes.index(event.filename)
  myFiles[Index].write("%s  %d   %d   %d   %7.2f  %d\n"%(event.filename, event.offset,    event.offset1,     event.address,   float(event.latency_ms),    event.timestamp))

b["events"].open_perf_buffer(print_event, page_cnt=4096)

while 1: 
  try: 
    b.kprobe_poll()
  except KeyboardInterrupt:
    print()
    print("Detaching...")
    exit()


