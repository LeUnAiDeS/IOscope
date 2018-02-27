#!/usr/bin/ruby -w

require 'cute'
load 'Reservation.rb'
load 'Deployment.rb'
load 'InstallMongodb.rb'
load 'ConfigSvrs.rb'
load 'RouterSvrs.rb'
load 'ShardSvrs.rb'
load 'InstallBCC.rb'

class Main 
	
attr_accessor :configSvrN
attr_accessor :routesSvrN
attr_accessor :shardsSvrN

attr_accessor :shardsSvrNames
attr_accessor :routesSvrNames
attr_accessor :shardsSvrNames



attr_accessor :g5k   
attr_accessor :jobs

attr_accessor :reserve
attr_accessor :deploy
attr_accessor :config
attr_accessor :configSvrs
attr_accessor :routerSvrs
attr_accessor :shardSvrs

attr_accessor :err

def initialize(configSvrN, routesSvrN, shardsSvrN, replicatSetN, jobs)
  @g5k = Cute::G5K::API.new()
  @jobs = nil
  @reserve = nil 
  @deploy = nil 
  @config = nil
# for the exp
  @configSvrN = configSvrN
  @routesSvrN = routesSvrN
  @shardsSvrN = shardsSvrN
  @replicatSetN = replicatSetN
  @replicatSets = Array.new
 
  @configSvrNames = Array.new
  @routesSvrNames = Array.new  
  @shardsSvrNames = Array.new
  @ycsbClientName = nil

# for already reserved job
  if jobs != nil 
  @jobs= Array.new
  @jobs.push(@g5k.get_job("#{jobs[0]}", jobs[1]))
  end
end



def starts

if @jobs == nil 
@reserve = Reservation.new
@err, @jobs = @reserve.startReservation(@g5k, @configSvrN, @routesSvrN , @shardsSvrN )
checkSuccess(@err, "Reservation")
elsif 
 puts "[Console] :  Dealing with already reserved nodes..."
end 

#phase deployment
#puts "[Console] : Deploying the nodes with Debian8"
#@deploy = Deployment.new(@g5k, @jobs)
#@err = @deploy.startDeployment
#checkSuccess(@err, "Deployment")

#phase config
divideJobs = Array.new
divideJobs = @jobs.clone

# take the array of nodes and distribute it
nodes = ((divideJobs.first)["assigned_nodes"]).clone

puts "The configuration servers are : "
for i in 1..@configSvrN
  node = nodes.shift
  @configSvrNames.push(node)
  puts node
end 
puts "The routing servers are : "
for i in 1..@routesSvrN
   node = nodes.shift
   @routesSvrNames.push(node)
   puts node
end 


#### with replicas 
# d : number of machines in a data shard
d = @shardsSvrN/@replicatSetN


for i in 1..@replicatSetN
temp = Array.new
   1.upto(d) do 
      node = nodes.shift
      temp.push(node)
   end 
     # odd shards number, add the last to the first replicat set
    if (i == @replicatSetN and nodes.size != 0 )
              node = nodes.shift
              temp.push(node)
     end
   @replicatSets.push(temp)
end


puts "The replicat/sharding servers are : "
repNames = Array.new
rep = ""
@replicatSets.each do |m|     
  	rep  = [*('a'..'z')].sample(2).join
 	repNames.push(rep)
	m.each do |n|
	  #puts "#{rep}/#{n}"
           puts "#{n}"
       end 
	puts
end

puts "[Console] : installing the new kernel and  BPF_BCC"


 install kernel and bcc 
@config = InstallBCC.new(@jobs)
@config.installKernel

puts "[Console] : installing MongoDB"

@config = InstallMongodb.new(@jobs)
@config.installMongo3_4


puts "[Console] : Configuring #{configSvrN} Configuration servers of mongoDB"
configSvrs = ConfigSvrs.new 
configSvrs.startConfigurations(@configSvrNames)


puts "[Console] : Configuring #{routesSvrN} Routing servers of mongoDB"
routerSvrs = RouterSvrs.new 
routerSvrs.startConfigurations(@routesSvrNames, @configSvrNames)


puts "[Console] : Configuring #{shardsSvrN} Sharding servers of mongoDB"
shardSvrs = ShardSvrs.new 
shardSvrs.startConfigurations(repNames, @replicatSets,@routesSvrNames)


end

#for checking every phase after accomplishment
def checkSuccess (err, phase)
 if err == 1 
  puts "[console] : #{phase} phase is done successfully "
 else 
  puts puts "[console] : An error has occurred while the #{phase} phase, the current nodes will be released"
  #@sites.each do |site|  @g5k.release_all(site) end 
  exit(1)
 end
end

end

	

	

