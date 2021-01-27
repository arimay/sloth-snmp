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
].each do |item|
  p [:set, item]
  pp Snmp.set( peer, item, **options )

  topic  =  item[:topic]
  p [:get, topic]
  tuples  =  Snmp.get( peer, topic, **options )
  tuples.each do |_oid, tuple|
    p  tuple
  end
  puts
end
