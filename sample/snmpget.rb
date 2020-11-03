#
# bundle exec ruby sample/snmpget.rb
#

require  "sloth/snmp"

Snmp  =  Sloth::Snmp.new

options = {
#  bindto:    "10.0.2.15",
#  device:    "enp0s3",
}

peer  =  ARGV.shift  ||  "127.0.0.1:161"

[
  [ "sysDescr.0", "sysUpTime.0", "sysName.0" ],
  [ "1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0" ],
  "1.3.6.1.2.1.1.5.0",
].each do |topics|
  p [:get, topics]
  tuples  =  Snmp.get( peer, topics, **options )
  tuples.each do |_oid, tuple|
    p  tuple
  end
  puts
end
