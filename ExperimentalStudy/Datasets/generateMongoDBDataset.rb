#!/usr/bin/ruby

gem 'mongo', '~> 1.0'
require 'mongo'
require 'yaml'


config = YAML.load(DATA.read)
dbconfig = config[:mongodb]
docsconfig = config[:docs]

client = nil
begin
  # connect to the database
  client = Mongo::MongoClient.new(dbconfig[:hostname], dbconfig[:port],
    dbconfig[:options])
  client.connect unless client.connected?
  db = client.db(dbconfig[:db])
  #db.authenticate(dbconfig[:user], dbconfig[:password]) if dbconfig[:user]
  coll = db.collection(dbconfig[:collection])

  (docsconfig[:number]).times do
    data1 = File.read('/dev/urandom', rand(docsconfig[:min_size]..docsconfig[:max_size]))
    data2 = File.read('/dev/urandom',rand(docsconfig[:min_size]..docsconfig[:max_size]))
   # random array 
    length = rand(1..4)
    tempArray = Array.new
    for i in 1..length do
      temp = File.read('/dev/urandom',rand(docsconfig[:arrayMin]..docsconfig[:arrayMax]))
      tempArray.push(BSON::Binary.new(temp))
    end
    tempo =  rand(1..100000)
    # insert instruction
    coll.insert({ randNum: tempo, dateAdded: Time.now,  data1: BSON::Binary.new(data1), dataArray: tempArray, data2:  BSON::Binary.new(data2) } )
  end

rescue Mongo::MongoDBError => e
  abort "ERROR: MongoDB connection error [#{e.class.name}]\n  > #{e.message}"
ensure
  client.close if client && client.connected?
end

__END__

:docs:
  :number: 20_000_000     #number of docs
  :min_size: 512          # the size of each field will be limited between min_size and max_size 
  :max_size: 1024
  :arrayMin: 512         # the size of each field (inside the array) will be limited between min_size and max_size
  :arrayMax: 1024
:mongodb:                 # the destination of this data
  :hostname: 127.0.0.1
  :port: 27017
  :db: xilopix
  :collection: dump
  :options:
    :connect_timeout: 120
    :op_timeout: 300
