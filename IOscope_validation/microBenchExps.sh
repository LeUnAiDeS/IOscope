#!/bin/bash

# on debian, install fio, tested with fio-2.1.3
apt-get install -y fio

# variable to take the workloads types (IOengines
ArrayModes=(sync psync posixaio)
# pvsync vsync pvsync2 solarisaio windowsaio guasi external   => are not native, they could be installed and added to the list
# libaio splice sg rdma falloc  => use differnt dedicated syscalls
echo ${ArrayModes[*]}

ArrayModes1=(mmap)
echo ${ArrayModes1[*]}

# variable to take the access type 
ArrayAccess=(read write randread randwrite rw randrw)
echo ${ArrayAccess[*]}

#create a file of 32MByte using dd
dd if=/dev/zero of=testFile bs=1024K count=32 oflag=direct

#create a folder for results and another for the tests
mkdir results
mkdir tests 
cd tests

for i in "${ArrayModes[@]}"; do
for j in "${ArrayAccess[@]}"; do 
# clean the cache
echo 3 > /proc/sys/vm/drop_caches
echo "testing ${i} - ${j} ..."

if [[ "${j}" == "write" || "${j}" == "randwrite" || "${j}" == "rw" || "${j}" == "randrw" ]]; then # 
fio --name=../testFile  --ioengine=$i --rw=$j -size=32M  --direct=1 --numjobs=1 --group_reporting &


pattern="[0-9]+\s+[0-9]+"
while [[ ! "$(pidof fio)" =~ $pattern ]]; do sleep 0.01 ; done;  #wait if the process IO is not yet created
nohup python ../IOscope_tools/IOscope_classic.py  -p $(pidof -s fio) -w 2  &   #-s return the IO job
else
nohup python ../IOscope_tools/IOscope_classic.py   &   # without pid (could not be catched)

sleep 3

fio --name=../testFile  --ioengine=$i --rw=$j -size=32M  --direct=1  --numjobs=1 --group_reporting &

fi # if

echo "running fio ..." 

# execute the tracing code 

# test if fio is terminated 
while kill -0 $(pidof fio) 2> /dev/null; do sleep 1; done;  # wait for the process to finish

sleep 4 

#kill the tracing code  
kill $(pidof python)
echo "move the result file" 
mv testFile.1.0 ../results/${i}_${j}.csv
#remove files
rm ../testFile.1.0
rm -rf * 
done # inner for
done # outer for 



rm ../testFile 

# testing mmaps
for c in "${ArrayAccess[@]}"; do 
# clean the cache
echo 3 > /proc/sys/vm/drop_caches
echo "creating file fio ..." 
fio --name="../testFile"  -size=32M 
# execute the tracing code 
echo "testing mmap - ${c} ..."
python ../IOscope_tools/IOscope_mmap.py  -i $(ls -C -i ../testFile.1.0  | awk '{print $1}') &

sleep 5
echo "running fio ..." 
fio --name=../testFile  --ioengine=mmap --rw=$c -size=32M  --direct=0 --numjobs=1 --group_reporting & 

sleep 3
kill $(pidof python)
echo "move the result file" 
mv testFile.1.0 ../results/mmap_${c}.csv
#remove files
rm ../testFile.1.0
rm -rf * 
done # end for
