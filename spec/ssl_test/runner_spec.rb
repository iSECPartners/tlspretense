require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe Runner do
    let(:args) { [] }
    let(:stdin) { double("stdin") }
    let(:stdout) { double("stdout") }

    let(:test_foo) do
      {
        'alias' => 'foo',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end
    let(:test_bar) do
      {
        'alias' => 'bar',
        'name' => 'Baseline Happy Test',
        'certchain' => ['baseline', 'goodca'],
        'expected_result' => 'connect'
      }
    end
    let(:test_data) { [test_foo, test_bar] }
    let(:test_wrongcname) { double('test wrongcname') }
    let(:conf_certs) { double('conf certs') }
    let(:config) do
      double(
        "config",
        :tests => test_data,
        'certs' => conf_certs,
        'action' => :runtests,
        'pause?' => false,
        'loglevel' => Logger::INFO,
        'logfile' => nil,
        'packetthief' => {}
      )
    end
    let(:cert_manager) { double("certificate manager") }
    let(:report) { double('report', :print_results => nil) }
    let(:testcaseresult) { double('test case result') }
    let(:testcase) { double('test case', :run => testcaseresult) }
    let(:appcontext) { double('context') }
    let(:logger) { Logger.new(nil) }

    let(:conf_data) do
      {
        'certs' => conf_certs,
        'tests' => test_data,
        'packetthief' => {},
      }
    end

    before(:each) do
      YAML.stub(:load_file).and_return(conf_data)
      CertificateManager.stub(:new).and_return(cert_manager)
      SSLTestCase.stub(:new).and_return(testcase)
      SSLTestReport.stub(:new).and_return(report)
      AppContext.stub(:new).and_return(appcontext)
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
        Config.stub(:new).and_return(config)
      end
      context "when ARGS is empty" do
        let(:args) { [] }

        it "runs all defined tests" do
          subject.should_receive(:run_test).with(test_foo).ordered
          subject.should_receive(:run_test).with(test_bar).ordered

          subject.run
        end
      end

      context "when ARGS is ['wrongcname']" do
        let(:args) { ['wrongcname'] }

        it "it runs just the test named 'wrongcname'" do
          config.stub(:tests).with(['wrongcname']).and_return([test_wrongcname])
          subject.should_receive(:run_test).with(test_wrongcname)

          subject.run
        end

      end

    end

    describe "#run_test" do
      it "creates an ssl test case" do
        SSLTestCase.should_receive(:new).with(appcontext, report, test_data)

        subject.run_test test_data
      end
      it "runs the test case" do
        testcase.should_receive(:run).and_return(testcaseresult)

        subject.run_test test_data
      end
    end

    describe "pausing between tests" do
      context "when ARGV contains -p or --pause" do
        context "when ARGV specifies 1 test" do
          let(:args) { %w{-p baseline} }
          it "does not pause" do
            subject.stub(:run_test)

            subject.should_not_receive(:pause)

            subject.run
          end
        end
        context "when ARGV specifies 3 tests" do
          let(:args) { %w{-p baseline another athird} }

          let(:baseline) { double('baseline test desc') }
          let(:another) { double('another test desc') }
          let(:athird) { double('athird test desc') }

          it "pauses between each test" do
            Config.any_instance.stub(:tests).with(['baseline','another','athird']).and_return([baseline, another, athird])

            subject.should_receive(:run_test).with(baseline).ordered
            subject.should_receive(:pause).ordered
            subject.should_receive(:run_test).with(another).ordered
            subject.should_receive(:pause).ordered
            subject.should_receive(:run_test).with(athird).ordered

            subject.run
          end
        end
      end

      describe "#pause" do
        it "waits for the user to press enter to continue" do
          stdout.stub(:puts)
          stdin.should_receive(:gets)

          subject.pause
        end
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
        Config.stub(:new).and_return(config)
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

    end

  end
end
