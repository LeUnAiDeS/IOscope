# IOscope
This projects provides the different tools of IOscope as well as the necessary informations for reproducing the experimental study listed in the IOscope paper 



## validating IOscope
To test IOscope against all the supported workloads, you should do the follwing steps. 
Clone the IOscope project and get inide it: 
```
git clone https://github.com/LeUnAiDeS/IOscope.git
cd IOscope
```

Run the the provided script for IOscope validation: 
```
IOscope$ ./IOscope_validation/microBenchExps.sh
```
This will take a while in order to produce the results for each use case (e.g. testing *sync* IOengine of fio againt *read* workload). The testfile size is set to 32MBytes to reduce the execution time (you can change it regarding your needs).


If no errors are raised during the execution, you should see the results of all executed workloads. Check the results 
in a newly created folder *results* in *IOscope*. Each file consists of the I/O access patterns of the correspondent workload, as the files' names indicated. 

In addition, we provide a datasets of *IOscope* produced files regarding this validation. 
You can find them under the folder datasets.
```
IOscope$ ls IOscope_validation/datasets/
```
You can draw these I/O access patterns as follows:
```
IOscope$ cd IOscope_validation/datasets/
Ioscope/IOscope_validation/datasets/$ Rscript ../script.R out psync_rw.csv // draw only psync_rw.csv data
Ioscope/IOscope_validation/datasets/$ for i in *.csv; do Rscript ../script.R $i; done // to draw all files
```
This will produce a pdf file containing a correspondent figure for each dataset workload file.
Chenck now the *datasets* folder to visualize the drawn data.
