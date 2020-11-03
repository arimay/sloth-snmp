RSpec.describe Sloth::Snmp do

  peer  =  "127.0.0.1:161"
  snmp  =  Sloth::Snmp.new

  [
    { topic: "sysName.0",         type: SNMP::OctetString, value: "%.10f" % rand },
    { topic: "1.3.6.1.2.1.1.5.0", type: SNMP::OctetString, value: "%.10f" % rand },
  ].each do |tuple|
    it "#set #{tuple}" do
      snmp.set( peer, tuple )
      tuples  =  snmp.get( peer, tuple[:topic] )
      expect( tuples[ tuples.keys.first ][:value] ).to  eq( tuple[:value] )
    end
  end

end
