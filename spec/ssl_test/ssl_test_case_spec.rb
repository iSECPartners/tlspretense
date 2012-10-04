require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe SSLTestCase do
    let(:cert_manager) { double("cert_manager", :get_chain => double('chain'), :get_key => double('key')) }
    let(:config) do
      double("config", :dest_port => 443, :listener_port => 54321, :hosttotest => "my.hostname.com")
    end

    before(:each) do
      PacketThief.stub_chain(:redirect, :where, :run)
      PacketThief.stub(:revert)
      EM.stub(:run).and_yield
      TestListener.stub(:start)
    end


    describe "#run" do

      context "when the test description is for a baseline certificate" do
        let(:testdesc) do
          {
            'alias' => 'baseline',
            'name' => 'Baseline Happy Test',
            'certchain' => ['baseline', 'goodca'],
            'expected_result' => 'connect'
          }
        end

        it "acquires a certificate chain and key" do
          cert_manager.should_receive(:get_chain).with(%w{baseline goodca}).and_return([double('baseline cert'), double('goodca cert')])
          cert_manager.should_receive(:get_key).with('baseline').and_return(double('baseline key'))

          SSLTestCase.new(config, cert_manager, testdesc).run
        end

        describe "activating packet thief" do
          it "launches packet thief with configuration values" do
            @ptrule = double("ptrule")
            PacketThief.should_receive(:redirect).with(:to_ports => 54321).and_return(@ptrule)
            @ptrule.should_receive(:where).with(:protocol => :tcp, :dest_port => 443).and_return(@ptrule)
            @ptrule.should_receive(:run)

            SSLTestCase.new(config, cert_manager, testdesc).run
          end
        end

        it "starts an eventmachine event loop" do
          EM.should_receive(:run)
          SSLTestCase.new(config, cert_manager, testdesc).run
        end

        it "launches a test runner" do
          @stc = SSLTestCase.new(config, cert_manager, testdesc)

          @chain = double('chain')
          @key = double('baseline key')
          cert_manager.stub(:get_chain).with(%w{baseline goodca}).and_return(@chain)
          cert_manager.stub(:get_key).with('baseline').and_return(@key)
          TestListener.should_receive(:start).with('127.0.0.1',54321,@stc)

          @stc.run
        end

        it "returns an SSLTestResult object when finished" do
          SSLTestCase.new(config, cert_manager, testdesc).run.should be_kind_of SSLTestResult
        end

      end
    end

    #        describe "#result_callback" do
    #          subject { SSLTestCase.new(config, cert_manager, testdesc) }
    #
    #          context "when the expected result is connect" do
    #            before(:each) do
    #              testdesc['expected_result'] = 'connect'
    #            end
    #            context "when the test reports that the client connected" do
    #              before(:each) do
    #                subject.result_callback(
    #              end
    #              it { subject.should be_success }
    #              it { subject.result.should == :connected }
    #            end
    #            context "when the test reports that the client rejected" do
    #              it "sets success? to false"
    #            end
    #          end
    #          context "when the expected result is "
    #        end

  end
end


