RSpec.describe Sloth::Snmp do

  # RFC1158-MIB.yaml:191:snmpInTraps: 1.3.6.1.2.1.11.19
  # RFC1158-MIB.yaml:201:snmpOutTraps: 1.3.6.1.2.1.11.29

  port  =  1162
  snmp  =  Sloth::Snmp.new( bind: "0.0.0.0:#{port}" )
  queue  =  Queue.new

  [
    ["snmpInTraps",   ".1.3.6.1.2.1.11.19"],
    ["snmpOutTraps",  ".1.3.6.1.2.1.11.29"],
  ].each do |topic, oid|
    it "#trap #{topic}" do
      snmp.trap( topic ) do |trapname, _source_ip, _tuples|
        queue.push  trapname
      end

      cmnd  =  "snmptrap  -v 2c  -c public   127.0.0.1:#{port}  ''  #{oid}  2> /dev/null "
      %x[#{cmnd}]
      trapname  =  queue.pop
      name  =  trapname.gsub( /\A.*::/, "" )
      expect( name ).to eq( topic )

      snmp.untrap( topic )
    end
  end

end
