RSpec.describe Sloth::Snmp do

  peer  =  "127.0.0.1:161"
  snmp  =  Sloth::Snmp.new

  [
    [ "system",    "sysDescr.0" ],
    [ "internet",  "sysDescr.0" ],
    [ nil,         "sysDescr.0" ],
  ].each do |topic, answer|
    it "#walk #{topic}" do
      tuples  =  snmp.walk( peer, topic )
      oid  =  tuples.keys.first
      tuple  =  tuples[oid]
      name  =  tuple[:name].gsub( /\A.*::/, "" )
      expect( name ).to eq( answer )
    end
  end

end
