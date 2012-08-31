require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module PacketThief
  describe Ipfw do
    describe ".redirect" do
      context "when it is told to redirect TCP port 443 traffic to localhost port 654321" do
        it "calls iptables with a rule that performs the diversion" do

          Ipfw.should_receive(:system).with(*%W{/sbin/ipfw add fwd 127.0.0.1,65432 tcp from any to any 443}).and_return true


          Ipfw.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
        end
      end
    end

    describe ".revert" do
      context "when a rule has been previously added" do
        before(:each) do
          Ipfw.stub(:system).and_return(:true)
          Ipfw.redirect(:to_ports => 3234).where(:protocol => :tcp, :dest_port => 80).run
        end
        it "removes the rule" do
          Ipfw.should_receive(:system).with(*%W{/sbin/ipfw del fwd 127.0.0.1,3234 tcp from any to any 80}).and_return true

          Ipfw.revert
        end
      end
    end
  end
end

