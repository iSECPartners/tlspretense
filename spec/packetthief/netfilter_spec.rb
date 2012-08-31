require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module PacketThief
  describe Netfilter do
    describe ".redirect" do
      it { Netfilter.redirect.table.should == 'nat' }
      it { Netfilter.redirect.chain.should == 'PREROUTING' }

      context "when it is told to redirect TCP port 443 traffic to localhost port 654321" do
        it "calls iptables with a rule that performs the diversion" do
          Netfilter.should_receive(:system).with(*%W{/sbin/iptables -t nat -A PREROUTING -p tcp --destination-port 443 -j REDIRECT --to-ports 65432}).and_return true

          Netfilter.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
        end
      end
    end


    describe ".revert" do
      context "when a rule has been previously added" do
        before(:each) do
          Netfilter.stub(:system).and_return(:true)
          Netfilter.redirect(:to_ports => 3234).where(:protocol => :tcp, :dest_port => 80).run
        end
        it "removes the rule" do
          Netfilter.should_receive(:system).with(*%W{/sbin/iptables -t nat -D PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-ports 3234}).and_return true

          Netfilter.revert
        end
      end
    end

  end
end

