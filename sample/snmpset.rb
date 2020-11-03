#
# bundle exec ruby sample/snmpset.rb
#

require  "sloth/snmp"

Snmp  =  Sloth::Snmp.new

options = {
#  bindto:    "10.0.2.15",
#  device:    "enp0s3",
}

peer  =  ARGV.shift  ||  "127.0.0.1:161"

[
  { topic: "sysName.0", type: SNMP::OctetString, value: Time.now.to_s },
].each do |tuple|
  p [:set, tuple]
  pp Snmp.set( peer, tuple, **options )

# topics  =  [tuple[:topic]]
  topics  =   tuple[:topic]
  p [:get, topics]
  tuples  =  Snmp.get( peer, topics, **options )
  tuples.each do |_oid, tuple_|
    p  tuple_
  end
  puts
end
