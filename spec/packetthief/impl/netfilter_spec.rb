require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module PacketThief
module Impl
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

      context "when it is told to watch a particular interface" do
        it "calls iptables with a rule that performs the diversion" do
          Netfilter.should_receive(:system).with(*%W{/sbin/iptables -t nat -A PREROUTING -p tcp --destination-port 443 --in-interface eth1 -j REDIRECT --to-ports 65432}).and_return true

          Netfilter.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'eth1').run
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

    describe ".original_dest" do
      context "when passed an object that implements Socket's #getsockopt" do
        it "returns the destination socket's details" do
          @socket = double("socket")
          # @socket.should_receive(:getsockopt).with(Socket::IPPROTO_IP, Netfilter::SO_ORIGINAL_DST).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")
          @socket.should_receive(:getsockopt).with(Socket::IPPROTO_IP, Netfilter::SO_ORIGINAL_DST).and_return(Socket.pack_sockaddr_in(16178, "10.101.96.97"))

          Netfilter.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

      context "when passed an object that implements EM::Connection's #get_sock_opt" do
        it "returns the destination connection's details" do
          @socket = double("EM::Connection")
          # @socket.should_receive(:get_sock_opt).with(Socket::IPPROTO_IP, Netfilter::SO_ORIGINAL_DST).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")
          @socket.should_receive(:get_sock_opt).with(Socket::IPPROTO_IP, Netfilter::SO_ORIGINAL_DST).and_return(Socket.pack_sockaddr_in(16178, "10.101.96.97"))

          Netfilter.original_dest(@socket).should == [16178, "10.101.96.97"]
        end
      end

    end

  end
end
end
