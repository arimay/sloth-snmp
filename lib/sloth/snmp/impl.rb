require "snmp"

module Sloth
  class Snmp

    class Error < StandardError; end

    class UDPTransportExt < ::SNMP::UDPTransport
      def initialize( address_family, bindto: nil, device: nil )
        super  address_family
        if  bindto
          host, port  =  bindto.split(':')    rescue nil
          @socket.bind( host, port.to_i )
        end
        if  device
          @socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_BINDTODEVICE, device )
        end
      end
    end

    def initialize( mibs: nil, bind: nil, rocommunity: "public", rwcommunity: "private" )
      case  bind
      when  Integer, NilClass
        @host  =  "0.0.0.0"
        @port  =  bind || 162
      when  String
        host, port  =  bind.split(':')    rescue  nil
        if host.nil? || host.empty?
          @host  =  "0.0.0.0"
        else
          @host  =  host
        end
        if port.nil? || port.empty?
          @port  =  162
        else
          @port  =  port.to_i
        end
      else
        raise  Sloth::Snmp::Error, "invalid class. : %s" % bind.class
      end
      @rocommunity  =  rocommunity
      @rwcommunity  =  rwcommunity

      @mibs  =  SNMP::MIB.new
      @mibs.load_module( "RFC1155-SMI" )
      @mibs.load_module( "RFC1158-MIB" )

      case  mibs
      when  NilClass
        mibs  =  []
      when  Array
        # noop
      when  String
        mibs  =  [mibs]
      else
        raise  Sloth::Snmp::Error, "invalid class. : %s" % mibs.class
      end

      mibpath  =  mibs.shift
      while  mibpath
        mibbase  =  File.basename( mibpath )
        mibdir  =  File.dirname( mibpath )
        if ( mibdir == "." && mibbase == mibpath )
          @mibs.load_module( mibbase.gsub( /\..*\Z/, "" ) )
        else
          @mibs.load_module( mibbase.gsub( /\..*\Z/, "" ), mibdir )
        end
        mibpath  =  mibs.shift
      end

      @topics  =  {}
      @mutex  =  ::Mutex.new
    end

    def start_listener
      @thread  ||=  Thread.start do
        listener  =  SNMP::TrapListener.new( host: @host, port: @port, community: @rocommunity ) do |manager|
          manager.on_trap_v2c do |mesg|
            begin
              next    if mesg.error_status  !=  :noError

              source_ip  =  mesg.source_ip
              trap_oid  =  mesg.trap_oid.join(".")
              trapname  =  @mibs.name( trap_oid )
              items  =  {}
              mesg.each_varbind do |varbind|
                oid, item  =  * parse_varbind( varbind )
                items[oid]  =  item
              end
              Thread.start do
                @mutex.synchronize do
                  @topics[ trap_oid ]&.call( trapname, source_ip, items )
                end
              end

            rescue => e
              raise  Sloth::Snmp::Error, e.message

            end
          end
        end
        Thread.current[:listener]  =  listener
        listener.join
      end
    end

    def stop_listener
      @mutex.synchronize do
        @topics.clear
        @thread[:listener].exit
        @thread  =  nil
      end
    end

    def trap( *topics, &block )
      @mutex.synchronize do
        topics.each do |topic|
          trap_oid  =  SNMP::ObjectId.new( topic )  rescue  @mibs.oid( topic )
          @topics[trap_oid.to_str]  =  block
        end
      end
      start_listener
    end

    def untrap( *topics )
      @mutex.synchronize do
        topics.each do |topic|
          trap_oid  =  SNMP::ObjectId.new( topic )  rescue  @mibs.oid( topic )
          @topics.delete( trap_oid.to_str )
        end
      end
      stop_listener    if @topics.empty?
    end

    def get( peer, topics, **options )
      host, port  =  peer.split(':')  rescue  nil
      host  =  "127.0.0.1"    if  host.nil? || host.empty?
      port  =  (port || 161).to_i
      community  =  options[:rocommunity]  ||  @rocommunity

      case  topics
      when  String
        oids  =  [ ( SNMP::ObjectId.new( topics )  rescue  @mibs.oid( topics ) ) ]
      when  Array
        oids  =  topics.map do |topic|
          SNMP::ObjectId.new( topic )  rescue  @mibs.oid( topic )
        end
      else
        raise  Sloth::Snmp::Error, "topics missing."
      end

      if  options[:bindto] && options[:device]
        transport  =  UDPTransportExt.new( Socket::AF_INET, bindto: options[:bindto], device: options[:device] )
      end

      manager  =  SNMP::Manager.new( host: host, port: port, community: community, transport: transport )

      items  =  {}
      begin
        response  =  Thread.handle_interrupt( ::Timeout::Error => :on_blocking ) do
          manager.get( oids )
        end

        response.each_varbind do |varbind|
          oid, item  =  * parse_varbind( varbind )
          items[oid]  =  item
        end

      rescue  SNMP::RequestTimeout => e
        raise  Sloth::Snmp::Error, e.message

      rescue  => e
        raise  Sloth::Snmp::Error, e.message

      end
      items
    end

    def walk( peer, topic, **options )
      host, port  =  peer.split(':')  rescue  nil
      host  =  "127.0.0.1"    if  host.nil? || host.empty?
      port  =  (port || 161).to_i
      community  =  options[:rocommunity]  ||  @rocommunity

      if  options[:bindto] && options[:device]
        transport  =  UDPTransportExt.new( Socket::AF_INET, bindto: options[:bindto], device: options[:device] )
      end

      manager  =  SNMP::Manager.new( host: host, port: port, community: community, transport: transport )

      topic  ||=  "internet"
      base_oid  =  SNMP::ObjectId.new( topic )  rescue  @mibs.oid( topic )

      items  =  {}
      begin
        Thread.handle_interrupt( ::Timeout::Error => :on_blocking ) do
          manager.walk( base_oid ) do |varbind|
            oid, item  =  * parse_varbind( varbind )
            items[oid]  =  item
          end
        end

      rescue  SNMP::RequestTimeout => e
        raise  Sloth::Snmp::Error, e.message

      rescue  => e
        raise  Sloth::Snmp::Error, e.message

      end
      items
    end

    def set( peer, tuple, **options )
      host, port  =  peer.split(':')  rescue  nil
      host  =  "127.0.0.1"    if  host.nil? || host.empty?
      port  =  (port || 161).to_i
      community  =  options[:rwcommunity]  ||  @rwcommunity

      if  options[:bindto] && options[:device]
        transport  =  UDPTransportExt.new( Socket::AF_INET, bindto: options[:bindto], device: options[:device] )
      end

      varbind  =  build_varbind( tuple[:topic], tuple[:type], tuple[:value] )

      manager  =  SNMP::Manager.new( host: host, port: port, community: community, transport: transport )

      begin
        response  =  Thread.handle_interrupt( ::Timeout::Error => :on_blocking ) do
          manager.set( varbind )
        end
        response

      rescue  SNMP::RequestTimeout => e
        raise  Sloth::Snmp::Error, e.message

      rescue  => e
        raise  Sloth::Snmp::Error, e.message

      ensure
        manager.close
      end
    end

    def parse_varbind( varbind, keys: nil )
      keys  =  [:name, :value]    if keys.nil? || keys.empty?
      oid   =  varbind.name.to_str
      name  =  @mibs.name( oid )
      case  varbind.value
      when  SNMP::OctetString
        type  =  SNMP::OctetString
        valu  =  varbind.value.to_s
        if  /[^[:print:]]/.match( valu )
          valu  =  "0x" + valu.unpack("H*").shift
        end
      when  SNMP::Integer
        type  =  SNMP::Integer
        valu  =  varbind.value.to_i
      when  SNMP::Counter32
        type  =  SNMP::Counter32
        valu  =  varbind.value.to_i
      when  SNMP::IpAddress
        type  =  SNMP::IpAddress
        valu  =  varbind.value.to_s
      when  SNMP::ObjectId
        type  =  SNMP::ObjectId
        valu  =  varbind.value
      when  SNMP::NoSuchInstance, SNMP::NoSuchObject
        type  =  varbind.value
        valu  =  nil
      else
        type  =  varbind.value
        valu  =  nil
      end

      tuple  =  {}
      tuple[:name]  =  name    if keys.include?( :name )
      tuple[:type]  =  type    if keys.include?( :type )
      tuple[:value]  =  valu    if keys.include?( :value )
      [oid, tuple]
    end

    def build_varbind( topic, type, value )
      oid  =  SNMP::ObjectId.new( topic )  rescue  @mibs.oid( topic )
      case  type
      when  SNMP::OctetString
        SNMP::VarBind.new( oid, SNMP::OctetString.new( value ))
      when  SNMP::Integer
        SNMP::VarBind.new( oid, SNMP::Integer.new( value ))
      when  SNMP::Counter32
        SNMP::VarBind.new( oid, SNMP::Counter32.new( value ))
      when  SNMP::IpAddress
        SNMP::VarBind.new( oid, SNMP::IpAddress.new( value ))
      when  SNMP::ObjectId
        SNMP::VarBind.new( oid, SNMP::ObjectId.new( value ))
      else
        SNMP::VarBind.new( oid, SNMP::OctetString.new( value.to_s ))
      end
    end

  end
end
