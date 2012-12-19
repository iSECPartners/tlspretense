require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe TestManager do

    let(:config) do
      double("config",
             :dest_port => 443,
             :listener_port => 54321,
             :hosttotest => "my.hostname.com",
             :packetthief => {
               :protocol => 'tcp',
               :dest_port => 443,
               :in_interface => 'en1'
             },
             :testing_method => 'tlshandshake',
             :pause? => false
            )
    end
    let(:certchain) { double('certchain') }
    let(:keychain) { [ double('firstkey'), double('secondkey'), double('cakey') ] }
    let(:goodcacert) { double('goodcacert') }
    let(:goodcakey) { double('goodcakey') }
    let(:cert_manager) do
      @cert_manager = double(
        "cert_manager",
        :get_chain => certchain,
        :get_keychain => keychain,
        :get_cert => double('cert'),
        :get_key => double('key')
      )
      @cert_manager.stub(:get_cert).with('goodca').and_return(goodcacert)
      @cert_manager.stub(:get_key).with('goodca').and_return(goodcakey)
      @cert_manager
    end
    let(:logger) { Logger.new(nil) }
    let(:app_context) { AppContext.new(config, cert_manager, logger) }
    let(:report) { double('report', :add_result => nil) }
    let(:listener) { double('listener') }

    let(:foo_test_data) do
      {
        'alias' => 'foo',
        'name' => 'test foo',
        'certchain' => [ 'a', 'b' ]
      }
    end
    let(:bar_test_data) do
      {
        'alias' => 'bar',
        'name' => 'test bar',
        'certchain' => [ 'c', 'd' ]
      }
    end
    let(:foo_test) { double('foo test',
                            :expected_result => 'connected',
                            :id => 'foo',
                            :description => 'foo test',
                           ) }
   let(:bar_test) { double('bar test',
                           :expected_result => 'connected',
                            :id => 'bar',
                            :description => 'bar test',
                          ) }
   let(:conf_tests_data) { [ foo_test_data, bar_test_data ] }
   let(:testlist) { [foo_test, bar_test] }

   subject { TestManager.new(app_context, testlist, report) }

   describe "#prepare_next_test" do
     context "when there are 3 tests in the testlist" do
       let(:testlist) { [ double('test1'), double('test2'), double('test3') ] }
       it "sets current_test to the first element of remaining_tests" do
         subject.current_test.should == testlist[0]
         subject.remaining_tests.should == [testlist[1], testlist[2]]

         subject.prepare_next_test

         subject.current_test.should == testlist[1]
         subject.remaining_tests.should == [testlist[2]]
       end

       context "when the application does not want to pause after each test" do
         before(:each) { config.stub(:pause?).and_return(false) }
         it "does not set paused to true" do
           subject.prepare_next_test

           subject.paused?.should == false
         end
       end
       context "when the application wants to pause after each test" do
         before(:each) { config.stub(:pause?).and_return(true) }
         it "sets paused to true" do
           subject.prepare_next_test

           subject.paused?.should == true
         end
       end
     end

     context "when there are no tests remaining" do
       let(:testlist) { [double('test1')] }
       it "stops testing" do
          subject.should_receive(:stop_testing)

          subject.prepare_next_test
       end
     end

   end

   describe "#test_completed" do
     let(:result) { double("result", :description= => nil,
                           :expected_result= => nil, :actual_result= => nil,
                           :start_time= => nil, :stop_time= => nil) }
     before(:each) do
       SSLTestResult.stub(:new).and_return(result)
     end

     context "when the current test is 'foo'" do
       before(:each) do
         subject.current_test = foo_test
       end

       context "when the expected result is a successful connection" do

         context "when the listener reports success" do
           it "creates a result that reports passing" do

             SSLTestResult.should_receive(:new).with('foo', true).and_return(result)
             result.should_receive(:description=).with('foo test')
             result.should_receive(:expected_result=).with('connected')
             result.should_receive(:actual_result=).with('connected')
             result.should_receive(:start_time=)
             result.should_receive(:stop_time=)

             subject.test_completed(:connected)
           end
           it "adds the result to a report" do

             report.should_receive(:add_result).with(result)

             subject.test_completed(:connected)
           end

           it "prepares for the next test" do
             subject.should_receive(:prepare_next_test)

             subject.test_completed(:connected)
           end

         end

         context "when the listener reports rejected" do
           it "creates a result that reports not passing" do
             SSLTestResult.should_receive(:new).with('foo', false).and_return(result)
             result.should_receive(:description=).with('foo test')
             result.should_receive(:expected_result=).with('connected')
             result.should_receive(:actual_result=).with('rejected')
             result.should_receive(:start_time=)
             result.should_receive(:stop_time=)

             subject.test_completed(:rejected)
           end
           it "adds the result to a report" do
             report.should_receive(:add_result).with(result)

             subject.test_completed(:rejected)
           end
         end

         context "when the listener reports a still running test that has stopped" do
           it "just returns" do
             SSLTestResult.should_not_receive(:new)

             subject.test_completed(:running)
           end
         end
         context "when the listener reports connected" do
           it "creates a result that reports passing" do
             SSLTestResult.should_receive(:new).with('foo', true).and_return(result)

             subject.test_completed(:connected)
           end
         end
         context "when the listener reports sentdata" do
           it "creates a result that reports passing" do
             SSLTestResult.should_receive(:new).with('foo', true).and_return(result)

             subject.test_completed(:sentdata)
           end
         end

       end

       context "when the configuration requires the client to send data for it to consider it to be connected" do
         before(:each) do
           config.stub(:testing_method).and_return('senddata')
         end
         context "when the expected result is a successful connection" do
           before(:each) do
             foo_test.stub(:expected_result).and_return('connected')
           end

           context "when the listener reports rejected" do
             it "creates a result that reports not passing" do
               SSLTestResult.should_receive(:new).with('foo', false).and_return(result)

               subject.test_completed(:rejected)
             end
           end

           context "when the listener reports connected" do
             it "creates a result that reports not passing" do
               SSLTestResult.should_receive(:new).with('foo', false).and_return(result)

               subject.test_completed(:connected)
             end
           end

           context "when the listener reports sentdata" do
             it "creates a result that reports passing" do
               SSLTestResult.should_receive(:new).with('foo', true).and_return(result)

               subject.test_completed(:sentdata)
             end
           end

         end
         context "when the expected result is a rejected connection" do
           before(:each) do
             foo_test.stub(:expected_result).and_return('rejected')
           end

           context "when the listener reports rejected" do
             it "creates a result that reports not passing" do
               SSLTestResult.should_receive(:new).with('foo', true).and_return(result)

               subject.test_completed(:rejected)
             end
           end

           context "when the listener reports connected" do
             it "creates a result that reports not passing" do
               SSLTestResult.should_receive(:new).with('foo', true).and_return(result)

               subject.test_completed(:connected)
             end
           end

           context "when the listener reports sentdata" do
             it "creates a result that reports passing" do
               SSLTestResult.should_receive(:new).with('foo', false).and_return(result)

               subject.test_completed(:sentdata)
             end
           end
         end
       end

     end
   end

   describe "#unpause" do
     context "when the manager is paused" do
       before(:each) do
         config.stub(:pause?).and_return(true)
         subject.prepare_next_test
       end

       it "unpauses the manager" do
         subject.unpause

         subject.paused?.should == false
       end
     end
   end

   describe "#stop_testing" do
     context "when the manager is bound to a listener" do
       before(:each) { subject.listener = listener }
       it "stops the listener" do
         listener.should_receive(:stop_server)

         subject.stop_testing
       end
     end
   end

  end
end
