#!/usr/bin/ruby -w


class Deployment

attr_accessor :g5k
attr_accessor :jobs 

def initialize(g5k, jobs)
 @g5k = g5k
 @jobs = jobs 
end

def startDeployment
#deploying nodes
for job in @jobs 
  puts "[console] : Starting the deployment parallel on nodes :  #{job["assigned_nodes"]} ..."
  @g5k.deploy(job, :nodes => job["assigned_nodes"], :env => "ubuntu1404-x64-min", :keys =>"~/.ssh/id_rsa")
end
 
# waiting for deployment to finish 
 for job in @jobs 
  puts "[console] : Waiting for deployment to finish on  #{job["assigned_nodes"]}"
  @g5k.wait_for_deploy(job)
 end

return(1)
rescue Exception => e
   puts e
   return(-1)
end

end
	

	

