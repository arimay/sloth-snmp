RSpec.describe Sloth::Snmp do

  peer  =  "127.0.0.1:161"
  snmp  =  Sloth::Snmp.new

  [
    [ [ "sysDescr.0", "sysUpTime.0", "sysName.0" ], [ "sysDescr.0", "sysUpTime.0", "sysName.0" ] ],
    [ [ "1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0" ], [ "sysDescr.0", "sysUpTime.0"              ] ],
    [ "1.3.6.1.2.1.1.5.0"                         , [                              "sysName.0" ] ],
  ].each do |params, answers|
    it "#get #{params}" do
      tuples  =  snmp.get( peer, params )
      names  =  tuples.values.map do |tuple|
        tuple[:name].gsub( /\A.*::/, "" )
      end
      expect( names ).to  match_array( answers )
    end
  end

end
