#!/usr/bin/ruby
#  chmod +x nom de fichier pour le rendre executable

#
# by Abdulqawi Saif
# 31 Dec. 2015
#

load 'Main.rb'

class Launcher
  
#settings of user

fail "[console]: You must enter the number of nodes of ConfigServers,RoutesServers, and shardsSevers" unless (ARGV.size ==  4  or ARGV.size == 7)


if ARGV.size ==  4 

configSvrN = ARGV[0].to_i
routesSvrN = ARGV[1].to_i
shardsSvrN = ARGV[2].to_i
replicatSetN = ARGV[3].to_i
main = Main.new(configSvrN, routesSvrN, shardsSvrN, replicatSetN, nil)
main.starts

# the previous parameters and -j site jobId => for the already reserved nodes
elsif ARGV.size ==  7

configSvrN = ARGV[0].to_i
routesSvrN = ARGV[1].to_i
shardsSvrN = ARGV[2].to_i
replicatSetN = ARGV[3].to_i

jobs =[ ARGV[5].to_s,  ARGV[6].to_i]
main = Main.new(configSvrN, routesSvrN, shardsSvrN, replicatSetN, jobs)
main.starts
end


end

