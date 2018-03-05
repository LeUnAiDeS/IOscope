# IOscope
This project provides the different tools of IOscope as well as the necessary information for reproducing the experimental study listed in the IOscope paper 


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


## Datasets and a reproducible example 

Datasets folder contains two scripts for generating Cassandra & MongoDB datasets. 

I didn't push all the  data files as they are very large, but if you want to 
reproduce the experiments using my data, send my an e-mail and I will send you back the data files. 
However, I uploaded a data file of a MongoDB shard used to produce Figure 10 in IOscope paper.
THere is a link: https://drive.google.com/file/d/0Bzu8JSTIH-U0OFFsNE84U1ktcXM/view?usp=sharing

To reproduce the experiment:  <br />
1- Stop mongod daemon.   <br />
2- extract the data to a folder and then make this folder as the data folder of MongoDB  <br />
3- start the mongod daemon again  <br />
4- connect to the daemon using mongo command in the command line.  <br />
5- try to start the indexing process  <br />

```
$ kill $(pidof mongod)
tar xf dump.tar MognoDB\_folder
$ mongod --config  /etc/mongodb.conf --port 27017 &
$ mongo
mongo> use xilopix
mongo> db.dump.createIndexes({randNum:1})
```
In another shell, clone IOscope ad start the IOscope\_classic tool as follwows: 

```
$ git clone https://github.com/LeUnAiDeS/IOscope.git
$ python Ioscope/IOscope_tools/IOscope_classic -p $(pidof mongod) -w 2 & 
```

When the worload is terminated, exist the tracing process, and look at the generated files. Among them you will a file named with with collectin as a prefix. Open it to see the order of the offsets inside or make a sample draw of the sequences of offsets against the offsets themselves. 

Then, apply our solution as described in the paper. Make a dump using mongodump (with xilopix as a db , and dump as a collection name. Then, restore the data to MongoDB folder and re-index the same field again with launching our IOscope\_classic 
to get the differences in terms of indexation time and the I/O access patterns.



## Reproducing I/O patterns figures of IOscope paper

The obtained data for of the I/O patterns figures of the IOscope paper can be found here: [usecase\_experiments](usecase\_experiments/Results/). <br /> You can draw them using the provided R script insdie the usecase\_experiments folder. For example: 

```
IOscope/usecase_experiments/StandaloneMongoDB$ Rscript ../drawingPatterns.R HDD_result.csv   
IOscope/usecase_experiments/StandaloneMongoDB$ evince outOfTheExecutedExample.pdf   // to visualize the produced I/O patterns
```
