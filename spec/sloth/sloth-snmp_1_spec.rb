RSpec.describe Sloth::Snmp do
  it "#new" do
    expect( Sloth::Snmp.new.class ).to  eq( Sloth::Snmp )
  end

  it "#new( mibs )" do
    expect( Sloth::Snmp.new( mibs: "RS-232-MIB.yaml" ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( mibs: "spec/sloth/RFC1414-MIB.yaml" ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( mibs: ["RS-232-MIB.yaml"] ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( mibs: ["spec/sloth/RFC1414-MIB.yaml"] ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( mibs: ["RS-232-MIB.yaml", "spec/sloth/RFC1414-MIB.yaml"] ).class ).to  eq( Sloth::Snmp )
  end

  it "#new( bind )" do
    expect( Sloth::Snmp.new( bind: "0.0.0.0" ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( bind: "0.0.0.0:1161" ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( bind: ":1161" ).class ).to  eq( Sloth::Snmp )
    expect( Sloth::Snmp.new( bind: 1161 ).class ).to  eq( Sloth::Snmp )
  end

  it "#new( rocommunity )" do
    expect( Sloth::Snmp.new( rocommunity: "public" ).class ).to  eq( Sloth::Snmp )
  end

  it "#new( rwcommunity )" do
    expect( Sloth::Snmp.new( rwcommunity: "private" ).class ).to  eq( Sloth::Snmp )
  end
end
