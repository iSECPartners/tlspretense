require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe SSLTestCase do
    let(:cert_manager) { double("cert_manager", :get_chain => double('chain'), :get_keychain => double('keychain'), :get_cert => double('cert'), :get_key => double('key')) }
    let(:config) do
      double("config", :dest_port => 443, :listener_port => 54321, :hosttotest => "my.hostname.com", :packetthief => { :protocol => 'tcp', :dest_port => 443, :in_interface => 'en1' } )
    end
    let(:testdesc) do
      {
        'alias' => 'baseline',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end
    let(:report) { double("report", :add_result => nil) }


    before(:each) do
      PacketThief.stub_chain(:redirect, :where, :run)
      PacketThief.stub(:revert)
      EM.stub(:run).and_yield
      EM.stub(:add_periodic_timer)
      EM.stub(:open_keyboard)
      TestListener.stub(:start)
    end

    subject { SSLTestCase.new(config, cert_manager, report, testdesc) }

    describe "#run" do

      context "when the test description is for a baseline certificate" do
        it "acquires a certificate chain and key" do
          cert_manager.should_receive(:get_chain).with(%w{baseline goodca}).and_return([double('baseline cert'), double('goodca cert')])
          cert_manager.should_receive(:get_keychain).with(%w{baseline goodca}).and_return([double('baseline key'), double('goodca key')])

          subject.run
        end

        describe "activating packet thief" do
          it "launches packet thief with configuration values" do
            @ptrule = double("ptrule")
            PacketThief.should_receive(:redirect).with(:to_ports => 54321).and_return(@ptrule)
            @ptrule.should_receive(:where).with(:protocol => 'tcp', :dest_port => 443, :in_interface => 'en1').and_return(@ptrule)
            @ptrule.should_receive(:run)

            subject.run
          end
        end

        it "starts an eventmachine event loop" do
          EM.should_receive(:run)

          subject.run
        end

        it "launches a test runner" do
          TestListener.should_receive(:start).with('',54321,subject)

          subject.run
        end

      end
    end

    describe "#test_completed" do
      let(:listener) { double("listener", :stop_server => nil) }
      let(:result) { double("result", :description= => nil,
                            :expected_result= => nil, :actual_result= => nil,
                            :start_time= => nil, :stop_time= => nil) }
      before(:each) do
        SSLTestResult.stub(:new).and_return(result)
      end

      context "when the expected result is a successful connection" do
        before(:each) do
          testdesc['expected_result'] = 'connected'
        end

        context "when the listener reports success" do
          it "creates a result that reports passing" do

            SSLTestResult.should_receive(:new).with('baseline', true).and_return(result)
            result.should_receive(:description=).with('Baseline Happy Test')
            result.should_receive(:expected_result=).with('connected')
            result.should_receive(:actual_result=).with('connected')
            result.should_receive(:start_time=)
            result.should_receive(:stop_time=)

            subject.test_completed(listener, :connected)
          end
          it "adds the result to a report" do

            report.should_receive(:add_result).with(result)

            subject.test_completed(listener, :connected)
          end

          it "stops the current listener's server socket" do
            listener.should_receive(:stop_server)

            subject.test_completed(listener, :connected)
          end

          it "reverts PacketThief" do
            PacketThief.should_receive(:revert)

            subject.test_completed(listener, :connected)
          end

          context "when the SSLTestCase started the event loop" do
            before(:each) do
              EM.stub(:reactor_running?).and_return(false)
              EM.should_receive(:run).and_yield
              TestListener.stub(:start)
              subject.run
            end

            it "stops the event loop" do
              EM.should_receive(:stop_event_loop)

              subject.test_completed(listener, :connected)
            end
          end

          context "when the SSLTestCase did not start the event loop" do
            before(:each) do
              EM.stub(:reactor_running?).and_return(true)
              EM.should_not_receive(:run)

              subject.run
            end

            it "does not stop the event loop" do
              EM.should_not_receive(:stop_event_loop)

              subject.test_completed(listener, :connected)
            end
          end

        end

        context "when the listener reports rejected" do
          it "creates a result that reports not passing" do
            SSLTestResult.should_receive(:new).with('baseline', false).and_return(result)
            result.should_receive(:description=).with('Baseline Happy Test')
            result.should_receive(:expected_result=).with('connected')
            result.should_receive(:actual_result=).with('rejected')
            result.should_receive(:start_time=)
            result.should_receive(:stop_time=)

            subject.test_completed(listener, :rejected)
          end
          it "adds the result to a report" do
            report.should_receive(:add_result).with(result)

            subject.test_completed(listener, :rejected)
          end
        end

        context "when the listener reports a still running test that has stopped" do
          it "just returns" do
            SSLTestResult.should_not_receive(:new)
            EM.should_not_receive(:stop_event_loop)
            listener.should_not_receive(:stop_server)

            subject.test_completed(listener, :running)
          end
        end


      end
    end
  end
end


