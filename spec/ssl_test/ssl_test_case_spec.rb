require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe SSLTestCase do
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
             :testing_method => 'tlshandshake'
            )
    end
    let(:testdesc) do
      {
        'alias' => 'baseline',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end

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
    let(:conf_tests_data) { [ foo_test_data, bar_test_data ] }



    let(:listener) { double("listener", :logger= => nil, :stop_server => nil) }
    let(:report) { double("report", :add_result => nil) }
    let(:logger) { Logger.new(nil) }
    let(:app_context) { AppContext.new(config, cert_manager, logger) }


    before(:each) do
      PacketThief.stub_chain(:redirect, :where, :run)
      PacketThief.stub(:revert)
      EM.stub(:run).and_yield
      EM.stub(:add_periodic_timer)
      EM.stub(:open_keyboard)
      EM.stub(:stop_event_loop)
      TestListener.stub(:start).and_return(listener)
    end


    # list of configs, list to generate
    describe ".factory" do
      subject { SSLTestCase }
      context "when an empty list of tests to perform is passed" do
        it "returns SSLTestCases for all of the tests in the config data, in the original order" do
          @tests = subject.factory(app_context, conf_tests_data, [])

          @tests.length.should == conf_tests_data.length
          @tests.each do |test|
            test.class.should == subject
          end
        end
      end

      context "when ['foo'] is passed as an argument" do
        it "returns a list with just a 'foo' test case" do
          @tests = subject.factory(app_context, conf_tests_data, ['foo'])

          @tests.length.should == 1
        end
      end
      context "when ['bar', 'foo'] is passed as an argument" do
        it "returns a list with 'bar', then 'foo'" do
          @tests = subject.factory(app_context, conf_tests_data, ['bar', 'foo'])

          @tests.length.should == 2
          @tests[0].id.should == 'bar'
          @tests[1].id.should == 'foo'
        end
      end
    end

  end
end


