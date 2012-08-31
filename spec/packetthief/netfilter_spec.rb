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
  end

  class Netfilter
    describe IPTablesRule do
      describe "#run" do
        it "calls its handler's run" do
          @handler = double('handler')
          @rule = IPTablesRule.new(@handler, 'nat', 'PREROUTING')

          @handler.should_receive(:run).with(@rule)

          @rule.run
        end
      end
    end

  end
end

