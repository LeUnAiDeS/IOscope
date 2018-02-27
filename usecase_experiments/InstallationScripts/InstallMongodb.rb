#!/usr/bin/ruby -w


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'
require 'net/scp'

class InstallMongodb 
	
attr_accessor :jobs   

def initialize(jobs)
 @jobs = jobs 
end


def installMongo3_4
representatif = ""
 #use all nodes
  nodes = @jobs.first
Net::SSH::Multi.start do |n|
  nodes["assigned_nodes"].each do |node|
    n.use("root@#{node}")
    representatif = node
  end

  n.exec!("apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6")
  n.exec!("echo \"deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse\" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list")
  n.exec!("apt-get update")
  n.exec!("apt-get install -y mongodb-org")
 # n.exec!("service mongod reload")
  puts "Done"
  n.exec!("mkdir /tmp/mongodb")
  n.exec!("chown -R mongodb:mongodb /tmp/mongodb")


end

 Net::SCP.start("#{representatif}", "root") do |scp| #without pass, using keys
      scp.download! "/etc/mongod.conf", "mongod.conf"
   end
    
 
# paste Xilopix's options instead of that

  
   full_path = File.expand_path('mongod.conf')
#    File.open(full_path) { |source_file|
#   contents = source_file.read
#   # change dbpath to SSD
#   contents.sub!(/dbPath: \/var\/lib\/mongodb/, 'dbPath: /tmp/mongodb') 
#   #Journaling 
#    #contents.sub!(/enabled: true/, 'enabled: false')  
#    contents.sub!(/path: \/var\/log\/mongodb\/mongod.log/, 'path: /tmp/mongod.log')  
#    contents.sub!(/bindIp: 127.0.0.1/, 'bindIp: 0.0.0.0') 
#    ###contents.sub!(/\#replication:/, "replication: \n replSet: #{replica}") 
#    ###contents.sub!(/\#sharding:/, "sharding: \n  clusterRole: shardsvr")

 

   

#    File.open(full_path, "w+") { |f| f.write(contents) }}
  
     File.open(full_path, 'w') { |file| 
	file.puts("#System Log") 
                file.puts("systemLog.destination: file")
         	file.puts("systemLog.quiet: true")
                file.puts("systemLog.path: /tmp/mongod.log")
file.puts("")
file.puts("")
file.puts("")
	file.puts("#Process Management")
		file.puts("processManagement.pidFilePath: /tmp/mongod.pid")
file.puts("")
file.puts("")
file.puts("")

	file.puts("#storage")
	file.puts("storage.dbPath: /tmp/mongodb")
	file.puts("storage.journal.enabled: true")
	file.puts("storage.smallFiles: true")
	file.puts("storage.engine: wiredTiger")
	file.puts("storage.wiredTiger.collectionConfig.blockCompressor: snappy")
	file.puts("storage.wiredTiger.indexConfig.prefixCompression: true")
        file.puts("storage.wiredTiger.engineConfig.cacheSizeGB: 2")
file.puts("")
file.puts("")
file.puts("")
#	file.puts("#security")
#	file.puts("security.keyFile: /tmp/mongodb/keyfile")
file.puts("")
file.puts("")
file.puts("")
	file.puts("#Net")
	file.puts("net.bindIp:  0.0.0.0")
	file.puts("net.http.RESTInterfaceEnabled: true")

file.puts("")
file.puts("")
	file.puts("setParameter:")
	file.puts("   authenticationMechanisms: MONGODB-CR")
}




#generate a keyfile to be used to authonticate the instances
#keyFile = File.expand_path('keyfile')
#File.open(keyFile, 'w') { |file| 
#file.write(%x(openssl rand -base64 741))
#}


# send the files
nodes["assigned_nodes"].each do |node|
 Net::SCP.start("#{node}", "root") do |scp| #without pass, using keys
      scp.upload! "mongod.conf", "/etc/mongod.conf"
 #     scp.upload! "keyfile", "/tmp/mongodb/keyfile"
  end
end



# reload mongod in all the servers, and change permissions of keyfile
Net::SSH::Multi.start do |svrs|
  nodes["assigned_nodes"].each do |node|
    svrs.use("root@#{node}")
  end
 svrs.exec!("service mongod stop")
 #svrs.exec!("chmod 400 /tmp/mongodb/keyfile")


end


end 
end
	

	

