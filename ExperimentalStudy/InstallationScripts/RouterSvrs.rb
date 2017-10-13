#!/usr/bin/ruby -w


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'

class RouterSvrs 
	


def initialize()

end


def startConfigurations(namesOfSvrs, nameOfConf)

# I don't use the file mongod.conf here. Instead, i wilml pass only the --keyFile
command = "mongos --port 27017 --logpath /tmp/mongod.log --configdb confSvr/"

for config in nameOfConf
 command += "#{config}:27019,"
end
# to delete the last , 
command = command[0...-1]

puts "[console] : the command is : #{command}"
#mybe change thread inside the loop, in case of multi-routers 

puts "Starting a new thread to hanldle the RouterSvrs ..."

Thread.new {
Net::SSH::Multi.start do |curser|
 for svr in namesOfSvrs
    curser.use("root@#{svr}")
  end
 curser.exec!("service mongod stop")
 curser.exec!("nohup #{command} &")

end
}
sleep(100)
puts "[console] : Configuring the routing servers is done successfully" 


# verify the state of routers
Net::SSH::Multi.start do |curser|
 for svr in namesOfSvrs
    curser.use("root@#{svr}")
  end

 curser.exec("ps aux | grep mongo")
end


end 
end
	

