require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module TLSPretense
module TestHarness
  describe Runner do
    let(:args) { [] }
    let(:stdin) { double("stdin") }
    let(:stdout) { double("stdout", :puts => nil) }

    let(:test_foo_data) do
      {
        'alias' => 'foo',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end
    let(:test_bar_data) do
      {
        'alias' => 'bar',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end
    let(:test_data_list) { [test_foo_data, test_bar_data] }

    let(:test_foo) { SSLTestCase.new(test_foo_data) }
    let(:test_bar) { SSLTestCase.new(test_bar_data) }
    let(:test_list) { [test_foo, test_bar] }

    let(:test_listener) { double('test listener', :logger= => nil) }
    let(:test_manager) { double('test manager') }

    let(:test_wrongcname) { double('test wrongcname') }
    let(:conf_certs) { double('conf certs') }
    let(:config) do
      double(
        "config",
        :listener_port => 54321,
        :tests => test_data_list,
        'certs' => conf_certs,
        'action' => :runtests,
        'pause?' => false,
        'loglevel' => Logger::INFO,
        'logfile' => nil,
        'packetthief' => {},
        'hosttotest' => double('hosttotest')
      )
    end
    let(:cert_manager) { double("certificate manager") }
    let(:report) { double('report', :print_results => nil, :add_result => nil) }
    let(:testcaseresult) { double('test case result') }
    let(:testcase) { double('test case', :run => testcaseresult) }
    let(:appcontext) { double('context',
                             :config => config,
                             :test_manager => test_manager,
                             :test_manager= => nil,
                             ) }
    let(:logger) { Logger.new(nil) }

    let(:conf_data) do
      {
        'certs' => conf_certs,
        'tests' => test_data_list,
        'packetthief' => {},
      }
    end

    before(:each) do
      YAML.stub(:load_file).and_return(conf_data)
      CertificateManager.stub(:new).and_return(cert_manager)
      SSLTestCase.stub(:new).and_return(testcase)
      SSLTestReport.stub(:new).and_return(report)
      AppContext.stub(:new).and_return(appcontext)
      SSLTestCase.stub(:factory).and_return(test_list)
    end

    after(:each) do
      PacketThief.instance_variable_set(:@implementation, nil)
    end

    subject { Runner.new(args, stdin, stdout) }

    describe "#initialize" do
      before(:each) do
        Config.stub(:new).and_return(config)
      end

      context "when ARGS is empty" do
        let(:args) { [] }
        it "loads the config from the default location" do
          Config.should_receive(:new).and_return(config)

          subject
        end

        it "initializes a certificate manager" do
          CertificateManager.should_receive(:new).with(conf_certs).and_return(cert_manager)

          subject
        end

        it "initializes a logger" do
          @logger = Logger.new(nil) # logger on the line below is called after Logger.should_receive(:new), meaning that logger() triggers the expectation, or something.
          Logger.should_receive(:new).and_return(@logger)

          subject
        end

        it "creates an application context" do
          AppContext.should_receive(:new).with(config, cert_manager, kind_of(Logger)).and_return(appcontext)

          subject
        end

      end
    end

    describe "#run" do
      before(:each) do
        @logger = Logger.new(nil)
        Logger.stub(:new).and_return(@logger)
        Config.stub(:new).and_return(config)
        subject.stub(:start_packetthief)
        subject.stub(:stop_packetthief)
        subject.stub(:run_tests).and_return(report)
      end

      context "when the action is runtests" do
        before(:each) do
          PacketThief.stub_chain(:redirect, :where, :run)
          PacketThief.stub(:revert)

          config.stub(:action).and_return(:runtests)

        end

        context "when ARGS is empty" do
          let(:args) { [] }

          it "creates a default list of test cases" do
            SSLTestCase.should_receive(:factory).with(appcontext, config.tests,[]).and_return(double('list of SSLTestCases', :length => 10))

            subject.run
          end

          it "runs the tests" do
            subject.should_receive(:run_tests).with(test_list).and_return(report)

            subject.run
          end

          it "starts PacketThief before running the tests" do
            subject.should_receive(:start_packetthief).ordered
            subject.should_receive(:run_tests).ordered.and_return(report)

            subject.run
          end


          it "stops PacketThief after running the tests" do
            subject.should_receive(:run_tests).ordered.and_return(report)
            subject.should_receive(:stop_packetthief).ordered

            subject.run
          end
        end

        context "when ARGS is ['wrongcname']" do
          let(:args) { ['wrongcname'] }
          it "it tells the SSLTestCase factory to just return the test called 'wrongcname'" do
            SSLTestCase.should_receive(:factory).with(appcontext, config.tests,['wrongcname']).and_return(double('list with just wrongcname', :length => 1))

            subject.run
          end
        end

      end

    end

    describe "#run_tests" do
      before(:each) do
        Config.stub(:new).and_return(config)
        EM.stub(:run).and_yield
        EM.stub(:add_periodic_timer)
        EM.stub(:open_keyboard)
        EM.stub(:stop_event_loop)
        TestListener.stub(:start).and_return(test_listener)
        TestManager.stub(:new).and_return(test_manager)
        @logger = logger
        Logger.should_receive(:new).and_return(logger)
      end

      it "configures a new TestManager" do
        TestManager.should_receive(:new).with(appcontext, test_list, report, logger).and_return(test_manager)

        subject.run_tests test_list
      end

      it "starts an EventMachine event loop" do
        EM.should_receive(:run)

        subject.run_tests test_list
      end

      it "starts the TestListener" do
        TestListener.should_receive(:start).with('', 54321, test_manager).and_return(test_listener)

        subject.run_tests test_list
      end
    end

    describe "logger options" do
      context "when the command line sets the log level to WARN" do
        let(:args) { %w{--log-level=WARN} }
        it "sets the logger's level to WARN" do
          @logger = Logger.new(nil)

          Logger.stub(:new).and_return(@logger)

          @logger.should_receive(:level=).with(Logger::WARN)

          subject
        end
      end

      context "when the command line sets the log file to 'foo.txt'" do
        let(:args) { %w{--log-file=foo.txt} }
        it "sets the log file to foo.txt" do
          @logger = Logger.new(nil)

          Logger.should_receive(:new).with('foo.txt').and_return(@logger)

          subject
        end
      end

    end

    describe "configuring packetthief" do
      before(:each) do
        PacketThief.instance_variable_set(:@implementation, nil)
        Config.stub(:new).and_return(config)
      end
      after(:each) do
        PacketThief.instance_variable_set(:@implementation, nil)
      end
      context "when the config does not specify an implementation" do
        before(:each) do
          config.stub(:packetthief).and_return( {} )
        end

        it "does not explicitly configure a firewall implementation" do
          PacketThief.should_not_receive(:implementation=)

          subject
        end
      end

      context "when the config specifies netfilter" do
        before(:each) do
          config.stub(:packetthief).and_return( {'implementation' => 'netfilter'} )
        end

        it "sets the firewall to :netfilter" do
          PacketThief.should_receive(:implementation=).with('netfilter')

          subject
        end
      end

      context "when the config specifies manual(somehost)" do
        before(:each) do
          config.stub(:packetthief).and_return( {'implementation' => 'manual(somehost)', 'dest_port' => 654} )
          PacketThief.stub(:set_dest)
        end

        it "sets the firewall to :manual" do
          PacketThief.should_receive(:implementation=).with(:manual)

          subject
        end

        it "sets the manual destination to the given hostname and dest_port" do
          PacketThief.should_receive(:set_dest).with('somehost', 654)

          subject
        end
      end

      describe "the 'external' pseudo-implementation" do
        context "when the config specifies external(netfilter)" do
          before(:each) do
            config.stub(:packetthief).and_return( {'implementation' => 'external(netfilter)'} )
            PacketThief.stub(:set_dest)
          end

          it "it sets the firewall implementation to netfilter" do
            PacketThief.should_receive(:implementation=).with(/netfilter/i)

            subject
          end

          # Not enabling packetthief currently needs to happen in the test runner
        end
      end

    end

    describe "running packet thief" do
      before(:each) do
        Config.stub(:new).and_return(config)
      end

      describe "#start_packetthief" do
        before(:each) do
          config.stub(:listener_port).and_return(54321)
          config.stub(:packetthief).and_return({
               :protocol => 'tcp',
               :dest_port => 443,
               :in_interface => 'en1'
             })
        end

        it "launches packet thief with configuration values" do
          @ptrule = double("ptrule")
          PacketThief.should_receive(:redirect).with(:to_ports => 54321).and_return(@ptrule)
          @ptrule.should_receive(:where).with(:protocol => 'tcp', :dest_port => 443, :in_interface => 'en1').ordered.and_return(@ptrule)
          @ptrule.should_receive(:run).ordered

          subject.start_packetthief
        end

        context "when the packetthief implementation is 'external(netfilter)'" do
          before(:each) do
            config.stub(:packetthief).and_return( { 'implementation' => 'external(netfilter)' } )
          end
          it "does not redirect traffic itself" do
            PacketThief.should_not_receive(:redirect)

            subject.start_packetthief
          end
        end

      end

      describe "#stop_packetthief" do
        it "reverts PacketThief" do
          PacketThief.should_receive(:revert)

          subject.stop_packetthief
        end
      end

    end


  end
end
end
