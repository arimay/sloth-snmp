#
#      bundle exec ruby sample/snmptrap.rb
# sudo bundle exec ruby sample/snmptrap.rb
#
# RFC1158-MIB.yaml:191:snmpInTraps: 1.3.6.1.2.1.11.19
# RFC1158-MIB.yaml:201:snmpOutTraps: 1.3.6.1.2.1.11.29
#

require  "sloth/snmp"

port  =  ( ARGV.shift || ( Process::Sys.getuid  ==  0  ?  162  :  1162 ) )
p [:port, port]

Snmp  =  Sloth::Snmp.new( bind: port )

queue  =  Queue.new

p :ready
Snmp.trap( "snmpInTraps", "snmpOutTraps" ) do |trapname, source_ip, tuples|
#Snmp.trap( "1.3.6.1.2.1.11.19", "1.3.6.1.2.1.11.29" ) do |trapname, source_ip, tuples|
  p ["TRAP!!", :trapname, trapname, :source_ip, source_ip]
  tuples.each do |_oid, tuple|
    p  tuple
  end
  queue.push  trapname
end

p :wait
sleep  1
puts

p cmnd  =  "snmptrap  -v 2c  -c public   127.0.0.1:#{port}  ''  .1.3.6.1.2.1.11.19  2> /dev/null "
%x[#{cmnd}]
p queue.pop

p cmnd  =  "snmptrap  -v 2c  -c public   127.0.0.1:#{port}  ''  .1.3.6.1.2.1.11.29  2> /dev/null "
%x[#{cmnd}]
p queue.pop

p :untrap
Snmp.untrap( "snmpInTraps", "snmpOutTraps" )
# Snmp.untrap( "1.3.6.1.2.1.11.19", "1.3.6.1.2.1.11.29" )

sleep  1
p :quit
