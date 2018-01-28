# IOscope
This projects provides the different tools of IOscope as well as the necessary informations for reproducing the experimental study listed in the IOscope paper 



## Validating IOscope
To test IOscope against all the supported workloads, you should do the following steps. 
Clone the IOscope project and get inside it: 
```
git clone https://github.com/LeUnAiDeS/IOscope.git
cd IOscope
```

Run the the provided script for validating IOscope: 
```
IOscope$ ./IOscope_validation/microBenchExps.sh
```
This will take a while in order to produce the results for each pair of IOengine & access method(e.g. testing *sync* IOengine of fio against *read* workload). The testfile size is set to 32MBytes to reduce the execution time (you can change it regarding your needs).


If no errors are raised during the execution, you should see the results of all executed workloads. Check the results 
inside *results* in *IOscope*. Each file consists of the I/O access patterns of the correspondent workload, as the files' names indicate. 

In addition, we provide a partial dataset of *IOscope* results obtained from the validation process. 
You can find them in the folder datasets.
```
IOscope$ ls IOscope_validation/datasets/
```
You can draw these I/O access patterns as follows:
```
IOscope$ cd IOscope_validation/datasets/
Ioscope/IOscope_validation/datasets/$ Rscript ../script.R out psync_rw.csv // draw only psync_rw.csv data
Ioscope/IOscope_validation/datasets/$ for i in *.csv; do Rscript ../script.R $i; done // to draw all files
```
This will produce a pdf file containing a correspondent figure for each provided workload.
Chenck now the *datasets* folder to visualize the drawn data.


## Understanding the I/O flow inside the Linux Kernel
We modified the NOOP I/O scheduler inside the Linux kernel to expose the information about the number of the 
waiting I/O requests in order to determine the real-time flow of the I/O worklaods of the analyzed system.


*NoopIO* folder contains the modified files of the NOOP I/O scheduler, and our eBPF tool that consumes the exposed information.
To understand the rate of the I/O requests of any given system, you should replace the Noop I/O scheduler files in your kernel 
by those ones: 
```
   elevator.h      => can be found in this path: ~kernelSource/include/linux/
   noop-iosched.c  => can be found in this path: ~kernelSource/block/
``` 
Then you can start the dedicated tool to analyze the I/O flow as follows: 
```
 IOscope$ python NoopIO/NoopSchedTool.py  > saveData
 ```
 You should stop the exeuction of NoopSchedTool at the end of the SUT workload. This will produce a file containing I/O flow of the requests that were waiting in the scheduler during the exeuction. 
