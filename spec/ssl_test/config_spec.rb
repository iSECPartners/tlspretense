require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module SSLTest
  describe Config do
    let(:foo_test) do
      {
        'alias' => 'foo',
        'name' => 'test foo',
        'certchain' => [ 'a', 'b' ]
      }
    end
    let(:bar_test) do
      {
        'alias' => 'bar',
        'name' => 'test bar',
        'certchain' => [ 'c', 'd' ]
      }
    end
    let(:conf_tests) { [ foo_test, bar_test ] }
    let(:pt_data) do
      {
        'dest_port' => 1234,
        'protocol' => 'tcp',
        'in_interface' => 'foo'
      }
    end
    let(:conf_data) do
      {
        'packetthief' => pt_data,
        'certs' => {},
        'tests' => conf_tests
      }
    end

    let(:opts) do
      {
        :config => 'foo.yml',
      }
    end

    before(:each) { YAML.stub(:load_file).and_return(conf_data) }

    subject { Config.new(opts) }

    describe "#initialize" do
      it "loads yaml data from the specified file" do
        YAML.should_receive(:load_file).with('foo.yml').and_return(conf_data)

        subject
      end

      it "exposes the raw config through #raw" do
        YAML.stub(:load_file).and_return(conf_data)

        subject.raw.should == conf_data
      end
      # TODO: some basic schema validation on the config file?
    end

    describe "#tests" do
      context "when no argument is passed" do
        it "returns all of the tests in the config data, in the original order" do
          subject.tests.should == conf_tests
        end
      end

      context "when ['foo'] is passed as an argument" do
        it "returns a list with just 'foo'" do
          subject.tests(['foo']).should == [foo_test]
        end
      end
      context "when ['bar', 'foo'] is passed as an argument" do
        it "returns a list with 'bar', then 'foo'" do
          subject.tests(['bar', 'foo']).should == [bar_test, foo_test]
        end
      end

    end

    describe "#packetthief" do
      context "when a conf_data['packetthief']'s keys are strings" do
        it "adds symbol versions" do
          @pt = subject.packetthief
          @pt.each_key do |k|
            if k.kind_of? String
              @pt.should have_key k.to_sym
              @pt[k.to_sym].should == @pt[k]
            end
          end
        end
      end
    end

  end
end

