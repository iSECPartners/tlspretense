require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module PacketThief
module Impl
  describe Ipfw do
    before(:each) do
      Ipfw.stub(:system).and_return(:true)
    end

    describe ".redirect" do
      context "when it is told to redirect TCP port 443 traffic to localhost port 654321" do
        it "calls ipfw with a rule that performs the diversion" do

          Ipfw.should_receive(:system).with(*%W{/sbin/ipfw add set 30 fwd 127.0.0.1,65432 tcp from any to any dst-port 443}).and_return true

          Ipfw.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
        end
      end

      context "when it is run on a Mac OS X system" do
        it "calls sysctl to set net.inet.ip.scopedroute to 0" do
          with_constants :RUBY_PLATFORM => "x86_darwin10" do

            Ipfw.should_receive(:system).with(*%W{/usr/sbin/sysctl -w net.inet.ip.scopedroute=0}).ordered.and_return(true)
            Ipfw.should_receive(:system).ordered.and_return(true)

            Ipfw.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
          end
        end
      end

      context "when it is told to watch a particular interface" do
        it "calls ipfw with a rule that performs the diversion" do
          Ipfw.should_receive(:system).with(*%W{/sbin/ipfw add set 30 fwd 127.0.0.1,65432 tcp from any to any dst-port 443 recv eth1}).and_return true

          Ipfw.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'eth1').run
        end
      end

    end


    describe ".revert" do
      context "when a rule has been previously added" do
        before(:each) do
          Ipfw.redirect(:to_ports => 3234).where(:protocol => :tcp, :dest_port => 80).run
        end
        it "removes the rule" do
          Ipfw.should_receive(:system).with(*%W{/sbin/ipfw del set 30}).and_return true

          Ipfw.revert
        end
      end
    end

    describe ".original_dest" do
      context "when passed an object that implements Socket's #getsockname" do
        it "returns the destination socket's details" do
          @socket = double("socket")
          @socket.stub(:getsockname).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")

          Ipfw.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

      context "when passed an object that implements EM::Connection's #getsockname" do
        it "returns the destination connection's details" do
          @socket = double("EM::Connection")
          @socket.stub(:get_sockname).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")

          Ipfw.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

    end
  end
end
end
