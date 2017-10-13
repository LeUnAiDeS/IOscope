require 'cassandra'
require 'yaml'

FORKS_NUMBER = 20   # number of the generating threads

config = YAML.load(DATA.read)
docsconfig = config[:docs]

cluster = Cassandra.cluster(hosts: ['127.0.0.1'])

session = cluster.connect() 

session.execute("DROP TABLE IF EXISTS xilopix.dump")

session.execute("DROP KEYSPACE IF EXISTS xilopix")

session.execute("CREATE KEYSPACE xilopix WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}")

session  = cluster.connect('xilopix')


session.execute("CREATE TABLE dump (
  id uuid,
  randNum int,
  date timestamp,
  data1 text,
  data2 text,
  data3  text, 
  data4  text,
  data5  text,
  PRIMARY KEY (id)
);")

pids = []

  FORKS_NUMBER.times do |t|
    pids << fork do

cluster1 = Cassandra.cluster(hosts: ['127.0.0.1'])
session2  = cluster1.connect('xilopix')


insert = session2.prepare(
            "INSERT INTO dump (id, randNum, date, data1, data2, data3, data4, data5) VALUES (uuid(), :a, :b, :c, :d, :e, :f, :g)" 
          ) 

(docsconfig[:number]).times do

 tempo =  rand(1..100000)
 data1 = %x(cat /dev/urandom | base64 | head --bytes #{rand(docsconfig[:min_size]..docsconfig[:max_size])} )
 data2 = %x(cat /dev/urandom | base64 | head --bytes #{rand(docsconfig[:min_size]..docsconfig[:max_size])} )
 data3 = %x(cat /dev/urandom | base64 | head --bytes #{rand(docsconfig[:min_size]..docsconfig[:max_size])} )
 data4 = %x(cat /dev/urandom | base64 | head --bytes #{rand(docsconfig[:min_size]..docsconfig[:max_size])} )
 data5 = %x(cat /dev/urandom | base64 | head --bytes #{rand(docsconfig[:min_size]..docsconfig[:max_size])} )
 
 
 session2.execute(insert, arguments: {:a => tempo, :b =>  Time.now, :c => data1, :d => data2,:e => data3, :f => data4, :g => data5}, consistency: :one)

end 

end 
  end
  Process.waitall
  pids.clear
__END__

:docs:
  :number: 1_000_000 #for each pid! 20 * 1 =  20 million
  :min_size: 512   # each element will be limited between min_size and max_size
  :max_size: 1024




#End
