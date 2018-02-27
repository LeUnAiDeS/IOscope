#!/usr/bin/ruby -w


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'
require 'net/scp'

class ShardSvrs 
	


def initialize()

end


def startConfigurations(repNames, replicatSet, nameOfRouters)

replicaImage = repNames.clone
# configure the replicaSet
replicatSet.each do |r|
  replica = replicaImage.shift
# run the mongod of shards
Thread.new{
Net::SSH::Multi.start do |svrs|
 for machine in r
    svrs.use("root@#{machine}")
  end
    # lancer les threads des shards

    svrs.exec!("mongod --config /etc/mongod.conf --shardsvr  --port 27017 &")    
    #svrs.exec!("ps aux | grep mongo")
end # run parallel of code multi start
} # end thread

sleep(10)
end # end each r 



# configure the replicaSet
###########################
@masters = Array.new
replicaNames= repNames.clone
replicatSet.each do |r|
     tempName = r.shift
     tempRep = replicaNames.shift
  @masters.push(["#{tempName}","#{tempRep}"])
      
end  # replicaset do




# writing the mongo script to add all the shards, and create a db named "xilopix, with the described collections.
scriptMD = File.expand_path('script.js')
File.open(scriptMD, "w+") { |script|

 @masters.each do |machine, replicat|
	script.write("sh.addShard( \"#{machine}:27017\" ) \n")
 end
   script.puts("use xilopix")
   #script.puts("sh.enableSharding(\"xilopix\")")

   #script.puts("db.dump.ensureIndex({_id: \"hashed\"}) ")

   #script.puts("sh.shardCollection(\"xilopix.dump\",{\"_id\": \"hashed\"} )")

   ##script.write("for (var i= 1; i<= 500; i++) db.testCollection.insert({ x : i } ) \n")
   ##script.write("sh.status()")
}

sleep(10)
# upload the script on the router
representatifRouter = nameOfRouters.first
Net::SCP.start("#{representatifRouter}", "root") do |scp| #without pass, using keys
      scp.upload! "script.js", "script.js"
  end


# apply the script on the router
Net::SSH::Multi.start do |router|
 router.use("root@#{representatifRouter}")
 
  # execute the script on a mongos
  router.exec!("mongo < script.js")
  # remove the script
  #router.exec!("rm -f script.js")
 end

puts "it is done,, you can verify it "

end 
end
	

