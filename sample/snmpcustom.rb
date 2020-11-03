#
# bundle exec ruby sample/snmp_custom.rb
# bundle exec ruby sample/snmp_custom.rb  sample/SAMPLE-MIB.yml  10.0.2.1
#

require  "sloth/snmp"

config  =  {}
mibpath  =  ARGV.shift
if  mibpath
  config.merge!( mibs: mibpath )
end

Snmp  =  Sloth::Snmp.new( **config )

peer  =  ARGV.shift  ||  "127.0.0.1:161"

topic  =  "internet"
tuples  =  Snmp.walk( peer, topic )
tuples.each do |_oid, tuple|
  p  tuple
end
