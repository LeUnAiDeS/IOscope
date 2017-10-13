#!/usr/bin/ruby -w


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'

class ConfigSvrs 
	


def initialize()

end


def startConfigurations(namesOfSvrs)

Thread.new {
puts "Starting a new thread to handle the configSvrs ..."
Net::SSH::Multi.start do |svrs|
 for svr in namesOfSvrs
    svrs.use("root@#{svr}")
  end
 
 #svrs.exec!("nohup mongod --config /etc/mongod.conf --configsvr --dbpath /tmp/mongodb --port 27019 &")
 
#replica of Config Servers... one config server for testing porpuse ! 
  svrs.exec!("nohup mongod --config /etc/mongod.conf --configsvr --replSet confSvr --dbpath /tmp/mongodb --port 27019 &")
  # starting from 3.4  
  sleep(30)
  svrs.exec!("mongo --port 27019 <<< \"rs.initiate()\"")
  
end
}
sleep(50)

# for mongo 3.4, we must have a replSet for config servers
Net::SSH::Multi.start do |svrs|
 for svr in namesOfSvrs
    svrs.use("root@#{svr}")
  end
#  # starting from 3.4  
  svrs.exec!("mongo --port 27019 <<< \"rs.initiate()\"")

end

sleep(30)

puts "[console] : Configuring the servers of configuration is done successfully"

Net::SSH::Multi.start do |svrs|
 for svr in namesOfSvrs
    svrs.use("root@#{svr}")
  end


 svrs.exec("ps aux | grep mongo")

end


end 
end
	

