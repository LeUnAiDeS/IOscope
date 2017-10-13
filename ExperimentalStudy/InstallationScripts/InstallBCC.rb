#!/usr/bin/ruby -w


require 'cute'
require 'net/ssh'
require 'cute/net-ssh'
require 'net/scp'

class InstallBCC
	
attr_accessor :jobs   

def initialize(jobs)
 @jobs = jobs 
end


def installKernel
 #use all nodes
  nodes = @jobs.first
Net::SSH::Multi.start do |n|
  nodes["assigned_nodes"].each do |node|
    n.use("root@#{node}")
  end

  n.exec!("sed -i  '/Acquire*/s/^/#/' /etc/apt/apt.conf.d/00-proxy-guest")

end

 
# send the files

nodes["assigned_nodes"].each do |node|
 Net::SCP.start("#{node}", "root") do |scp| #without pass, using keys
      scp.upload! "install_kernel.sh", "install_kernel.sh"
      scp.upload! "install_bcc.sh", "install_bcc.sh"
  end
end

# execute the files
Net::SSH::Multi.start do |svrs|
  nodes["assigned_nodes"].each do |node|
    svrs.use("root@#{node}")
  end
 svrs.exec!("sh install_kernel.sh")

 svrs.exec("sudo reboot") 
end


#wait for the machines to run
sleep(150)


# execute the files                                                  
Net::SSH::Multi.start do |svrs|
  nodes["assigned_nodes"].each do |node|
    svrs.use("root@#{node}")
  end
 svrs.exec!("sh install_bcc.sh")

end




end 
end
	

	

