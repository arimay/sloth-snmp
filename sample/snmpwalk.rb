#
# bundle exec ruby sample/snmpwalk.rb
#

require  "sloth/snmp"

Snmp  =  Sloth::Snmp.new

options = {
#  bindto:    "10.0.2.15",
#  device:    "enp0s3",
}

peer  =  ARGV.shift  ||  "127.0.0.1:161"

[
  "system.8",
  "system.9",
  "mib-2.25.1",
  "internet",
  nil,
].each do |topic|
  p [:walk, topic] 
  tuples  =  Snmp.walk( peer, topic, **options )
  tuples.each do |_oid, tuple|
    p  tuple
  end
  puts
end
