require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module PacketThief
  describe PF do
    subject { PF }

    before(:each) do
      subject.stub(:system).and_return(:true)
    end

    # Either write our current ruleset to a file, or echo it into pfctl.
    describe ".redirect" do
      after(:each) do
        subject.revert
      end
      context "when it is told to redirect TCP port 443 traffic to localhost port 65432" do
        it "calls pfctl with a rule that performs the diversion" do

          subject.should_receive(:system).with(*['echo', 'pass in proto tcp from any to any port 443 divert-to 127.0.0.1 port 65432']+%W{| pfctl -a packetthief -f -}).and_return true

          subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
        end
      end

      context "when it is told to watch a particular interface" do
        it "calls pf with a rule that performs the diversion" do
          subject.should_receive(:system).with(*['echo', 'pass in on eth1 proto tcp from any to any port 443 divert-to 127.0.0.1 port 65432']+%W{| pfctl -a packetthief -f -}).and_return true

          subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'eth1').run
        end
      end

      context "when it is called with two rules" do
        it "sends both rules to pfctl on the second invocation" do
          subject.should_receive(:system).with(*['echo', 'pass in proto tcp from any to any port 80 divert-to 127.0.0.1 port 65432']+%W{| pfctl -a packetthief -f -}).ordered.and_return true
          subject.should_receive(:system).with(*['echo', "pass in proto tcp from any to any port 80 divert-to 127.0.0.1 port 65432\npass in proto tcp from any to any port 443 divert-to 127.0.0.1 port 65433"]+%W{| pfctl -a packetthief -f -}).ordered.and_return true

          subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 80).run
          subject.redirect(:to_ports => 65433).where(:protocol => :tcp, :dest_port => 443).run
        end
      end

    end


    describe ".revert" do
      context "when a rule has been previously added" do
        before(:each) do
          subject.redirect(:to_ports => 3234).where(:protocol => :tcp, :dest_port => 80).run
        end
        it "removes the packetthief anchor" do
          subject.should_receive(:system).with(*%W{pfctl -a packetthief -F rules}).and_return true

          subject.revert
        end
      end
    end

    describe ".original_dest" do
      context "when passed an object that implements Socket's #getsockname" do
        it "returns the destination socket's details" do
          @socket = double("socket")
          @socket.stub(:getsockname).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")

          subject.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

      context "when passed an object that implements EM::Connection's #getsockname" do
        it "returns the destination connection's details" do
          @socket = double("EM::Connection")
          @socket.stub(:get_sockname).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")

          subject.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

    end
  end
end

