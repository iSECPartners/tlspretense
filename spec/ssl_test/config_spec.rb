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
    let(:conf_data) do
      {
        'certs' => {},
        'tests' => conf_tests
      }
    end

    describe ".load_conf" do
      context "when no argument is passed" do
        it "loads from the default config" do
          Config.should_receive(:new).with(SSLTest::Config::DEFAULT)

          Config.load_conf
        end
      end
    end

    describe "#initialize" do
      it "loads yaml data from the specified file" do
        YAML.should_receive(:load_file).with('foo.yml').and_return(conf_data)

        Config.new('foo.yml')
      end
      it "exposes the raw config through #raw" do
        YAML.stub(:load_file).and_return(conf_data)

        Config.new('foo').raw.should == conf_data
      end
      # TODO: some basic schema validation on the config file?
    end

    describe "#tests" do
      before(:each) { YAML.stub(:load_file).and_return(conf_data) }

      context "when no argument is passed" do
        it "returns all of the tests in the config data, in the original order" do
          Config.load_conf.tests.should == conf_tests
        end
      end

      context "when ['foo'] is passed as an argument" do
        it "returns a list with just 'foo'" do
          Config.load_conf.tests(['foo']).should == [foo_test]
        end
      end
      context "when ['bar', 'foo'] is passed as an argument" do
        it "returns a list with 'bar', then 'foo'" do
          Config.load_conf.tests(['bar', 'foo']).should == [bar_test, foo_test]
        end
      end

    end

  end
end

