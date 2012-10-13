require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module PacketThief
  module Impl
    describe Manual do
      before(:each) do
        subject.stub(:system).and_return(:true)
      end

      subject {Manual}

      describe ".redirect" do
        context "when it is told to redirect TCP port 443 traffic to localhost port 654321" do
          it "does not call a external command" do
            subject.should_not_receive(:system)

            subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
          end
        end

        context "when it is told to watch a particular interface" do
          it "does not call a external command" do
            subject.should_not_receive(:system)

            subject.redirect(:to_ports => 65432).where(:protocol => :tcp, :dest_port => 443).run
          end
        end
      end

      describe ".revert" do
        context "when a rule has been previously added" do
          before(:each) do
            subject.redirect(:to_ports => 3234).where(:protocol => :tcp, :dest_port => 80).run
          end
          it "does not call a external command" do
            subject.should_not_receive(:system)

            subject.revert
          end
        end
      end

      describe ".original_dest" do
        after(:each) do
          subject.set_dest(nil, nil)
        end

        context "when .set_dest(host, port) has not been set" do
          it "raises an error" do
            expect { subject.original_dest(double('socket')) }.to raise_error
          end
        end

        context "when .set_dest(host, port) has been set" do
          before(:each) { subject.set_dest('somehost', 1234) }

          it "returns the specified port and host" do
            subject.original_dest(double('socket')).should == [1234, 'somehost']
          end
        end
      end

    end
  end
end
