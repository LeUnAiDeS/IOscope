#!/usr/bin/ruby 


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'
require 'net/scp'

# Optional, if you want to inject from a storageJob to
#the dump to the distributed cluster of MongoDB


class InjectDump


attr_accessor :job
attr_accessor :mongoRouter

def initialize(jobStorage, mongo)
	@job = jobStorage
   	@mongoRouter = mongo
end


def copyTheDump(user)
 puts "Copying data from inside g5kStorage  job into a mongos machine..."
 %x[scp /data/#{user}_#{@job}/dump/dump.tar root@#{@mongoRouter}:/]
end  #end copyTheDump

def injectMongo

Net::SSH::Multi.start do |server|
  server.use("root@#{@mongoRouter}")
    
# Extract the dump

 puts "Extracting dump inside mongos machine..."
server.exec!("tar -xf /dump.tar") # extract it to the root folder

# Restore the data into MongoDB

 puts "Injecting dump into MongoDB cluster..."
server.exec!("mongorestore -uxilopix -pxilopix -d xilopix dump/xilopix/") # extract it to the root folder

end # End ssh

end # End function

end  #end class 


fail "[console]: You must give (1) the s5k storage jobID, (2) the hostname of a mongoRouter" unless ARGV.size == 2
jobStorage = ARGV[0].to_i
router = ARGV[1].to_s
d= InjectDump.new(jobStorage,router)
# the user who reserved the storage's job
d.copyTheDump("asaif")
d.injectMongo()

