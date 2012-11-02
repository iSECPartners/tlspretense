require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module PacketThief
  module Impl
    describe PFRdr do
      subject { PFRdr }

      before(:each) do
        subject.stub(:system).and_return(:true)
        IO.stub(:popen)
      end

      # Either write our current ruleset to a file, or echo it into pfctl.
      describe ".redirect" do
        after(:each) do
          subject.revert
        end
        context "when it is told to redirect TCP port 443 traffic to localhost port 65432" do
          it "calls pfctl with a rule that performs the diversion" do
            @pfctlio = double('pfctl io')
            IO.should_receive(:popen) do |args, &block|
              args.should == %W{pfctl -a packetthief -f -}
              block.call(@pfctlio)
              `true`
              $?.exitstatus.should == 0
            end
            @pfctlio.should_receive(:puts).with("rdr proto tcp from any to any port 443 -> 127.0.0.1 port 65432")

            subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
          end
        end

        context "when it is told to watch a particular interface" do
          it "calls pf with a rule that performs the diversion" do
            @pfctlio = double('pfctl io')
            IO.should_receive(:popen) do |args, &block|
              args.should == %W{pfctl -a packetthief -f -}
              block.call(@pfctlio)
              `true`
              $?.exitstatus.should == 0
            end
            @pfctlio.should_receive(:puts).with("rdr on eth1 proto tcp from any to any port 443 -> 127.0.0.1 port 65432")

            subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443, :in_interface => 'eth1').run
          end
        end

        context "when it is called with two rules" do
          it "sends both rules to pfctl on the second invocation" do
            @pfctlio = double('pfctl io')
            @pfctlio2 = double('pfctl io')
            IO.should_receive(:popen).ordered do |args, &block|
              args.should == %W{pfctl -a packetthief -f -}
              block.call(@pfctlio)
              `true`
              $?.exitstatus.should == 0
            end
            @pfctlio.should_receive(:puts).with("rdr proto tcp from any to any port 80 -> 127.0.0.1 port 65432")
            IO.should_receive(:popen).ordered do |args, &block|
              args.should == %W{pfctl -a packetthief -f -}
              block.call(@pfctlio2)
              `true`
              $?.exitstatus.should == 0
            end
            @pfctlio2.should_receive(:puts).with("rdr proto tcp from any to any port 80 -> 127.0.0.1 port 65432").ordered
            @pfctlio2.should_receive(:puts).with("rdr proto tcp from any to any port 443 -> 127.0.0.1 port 65433").ordered

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
        context "when passed an object that implements Socket's #getsockname and #getpeername" do
          let(:peername) { double('peername') }
          let(:sockname) { double('sockname') }
          let(:socket) { double('socket', :getpeername => peername, :getsockname => sockname) }

          before(:each) do
            Socket.stub(:unpack_sockaddr_in).with(peername).and_return([52999, '192.168.2.2'])
            Socket.stub(:unpack_sockaddr_in).with(sockname).and_return([54321, '127.0.0.1'])
          end

          context "when `pfctl -s state` returns info that includes the current connection" do
            let(:statetable) do
              <<-QUOTE.gsub(/^\s*/, '')
                No ALTQ support in kernel
                ALTQ related functions disabled
                ALL tcp 13.37.13.37:80 <- 192.168.2.2:52995       ESTABLISHED:ESTABLISHED
                ALL tcp 192.168.2.2:52995 -> 10.0.1.2:33596 -> 74.125.224.68:80       ESTABLISHED:ESTABLISHED
                ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:52998       CLOSED:SYN_SENT
                ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:52999       CLOSED:SYN_SENT
                ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:53000       CLOSED:SYN_SENT
                ALL tcp 127.0.0.1:54321 <- 173.194.79.147:443 <- 192.168.2.2:53001       CLOSED:SYN_SENT
                ALL udp 192.168.2.1:53 <- 192.168.2.2:53690       SINGLE:MULTIPLE
                ALL tcp 74.125.224.105:80 <- 192.168.2.2:53002       ESTABLISHED:ESTABLISHED
                ALL tcp 192.168.2.2:53002 -> 10.0.1.2:38466 -> 74.125.224.105:80       ESTABLISHED:ESTABLISHED
                ALL udp 224.0.0.251:5353 <- 10.0.1.4:5353       NO_TRAFFIC:SINGLE
                ALL udp ff02::fb[5353] <- fe80::72de:e2ff:fe41:5ddd[5353]       NO_TRAFFIC:SINGLE
              QUOTE
            end

            before(:each) do
              subject.stub(:`).with(/pfctl -s state/).and_return(statetable)
            end

            it "returns the original destination" do
              subject.original_dest(socket).should == [443, '173.194.79.147']
            end

          end

#          it "calls pf_get_orig_dest with the peer and own data" do
#            subject.should_receive(:pf_get_orig_dest).with(peername, sockname).and_return("\020\002?2\ne`a\000\000\000\000\000\000\000\000")
#
#            subject.original_dest(socket)
#          end
#
#          it "it returns the destination socket's details" do
#            subject.stub(:pf_get_orig_dest).with(peername, sockname).and_return("\x02\x02;\x10\x7F\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00")
#
#            subject.original_dest(socket).should == [ 15120, "127.0.0.1"]
#          end
        end

      end
    end
  end
end
