require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe Runner do
    let(:args) { [] }
    let(:stdin) { double("stdin") }
    let(:stdout) { double("stdout") }

    let(:test_foo) { double('test foo') }
    let(:test_bar) { double('test bar') }
    let(:test_data) { [test_foo, test_bar] }
    let(:test_wrongcname) { double('test wrongcname') }
    let(:conf_certs) { double('conf certs') }
    let(:config) { double("config", :tests => test_data, 'certs' => conf_certs, 'action' => :runtests, 'pause?' => false) }
    let(:cert_manager) { double("certificate manager") }
    let(:report) { double('report', :print_results => nil) }
    let(:testcaseresult) { double('test case result') }
    let(:testcase) { double('test case', :run => testcaseresult) }

    subject { Runner.new(args, stdin, stdout) }

    before(:each) do
      Config.stub(:new).and_return(config)
      CertificateManager.stub(:new).and_return(cert_manager)
      SSLTestCase.stub(:new).and_return(testcase)
      SSLTestReport.stub(:new).and_return(report)
    end

    describe "#initialize" do
      context "when ARGS is empty" do
        let(:args) { [] }
        it "loads the config from the default location" do
          Config.should_receive(:new).and_return(config)
          subject.stub(:run_test)

          subject.run
        end

        it "initializes a certificate manager" do
          CertificateManager.should_receive(:new).with(conf_certs).and_return(cert_manager)

          subject.stub(:run_test)
          subject.run
        end

      end
    end

    describe "#run" do
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
        SSLTestCase.should_receive(:new).with(config, cert_manager, report, test_data)

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
            subject.should_not_receive(:pause)

            subject.run
          end
        end
        context "when ARGV specifies 3 tests" do
          let(:args) { %w{-p baseline another athird} }

          let(:baseline) { double('baseline test desc') }
          let(:another) { double('another test desc') }
          let(:athird) { double('athird test desc') }

          before(:each) do
            Config.should_receive(:new) do |args|
              args[:pause].should == true
              config.stub(:pause?).and_return(true)
              config
            end
          end

          it "pauses between each test" do
            config.stub(:tests).with(['baseline','another','athird']).and_return([baseline, another, athird])

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

  end
end
