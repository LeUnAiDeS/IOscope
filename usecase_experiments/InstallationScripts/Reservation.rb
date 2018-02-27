#!/usr/bin/ruby -w


require 'cute'

class Reservation 
	

def initialize

end


def startReservation(g5k, confN, routesN, shardsN )
 @jobs= Array.new
 numOfNodes = confN+routesN+shardsN
# for i in 1..numOfNodes
    selectedSite = "nancy"
    puts "[console] : Reserving the nodes in '#{selectedSite}' ... "
    @jobs.push(g5k.reserve(:site => "#{selectedSite}",:cluster => "talc",:nodes => numOfNodes , :walltime => '08:00:00',:type => [:deploy,:production,:destructive], :keys => "~/.ssh/ id_rsa", :wait => true ))
#  end
 
 return[1 , @jobs]
rescue Exception => e
   puts e
   return[-1, nil]
end 


end
	

	

