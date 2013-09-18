require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper'))

module PacketThief
  describe Logging do
    class LoggingObj
      include Logging
    end

    let(:logger) { Logger.new(nil) }
    before(:each) { Logging.logger = logger }

    describe "an object that has included PacketThief::Logging" do
      subject { LoggingObj.new }

      it "does not expose its log methods" do
        expect { subject.logdebug("some message") }.to raise_error NoMethodError
      end

      context "when Logging.logger is unset" do
        before(:each) { Logging.logger = nil }

        it { expect { subject.send(:logdebug, "some message")}.to_not raise_error }
      end

      context "when Logging.logger is set" do

        it "sends a message with the classname to the logger" do
          logger.should_receive(:log).with(Logger::DEBUG, subject.class.to_s + ": hello world!")

          subject.send(:logdebug, 'hello world!')
        end
        it "prints an optional argument to the logger" do
          logger.should_receive(:log).with(Logger::DEBUG, subject.class.to_s + ": a message: data: 12345")

          subject.send(:logdebug, 'a message', :data => 12345)
        end
        it "prints multiple optional arguments to the logger in sorted order" do
          logger.should_receive(:log).with(Logger::DEBUG, /#{subject.class.to_s}: a message: astring: ['"]inspect this['"], data: 12345/)

          subject.send(:logdebug, 'a message', :data => 12345, :astring => "inspect this")
        end
      end
    end

    context "when added to a class" do
      class ClassToTest
        class << self
          include Logging
        end
      end

      subject { ClassToTest }

      it "sets component to the class name" do
        logger.should_receive(:log).with(Logger::DEBUG, "#{subject.name}: a message")

        subject.send(:logdebug , "a message")
      end
    end
    context "when added to a module" do
      module ModToTest
        class << self
          include Logging
        end
      end

      subject { ModToTest }

      it "sets component to the module name" do
        logger.should_receive(:log).with(Logger::DEBUG, "#{subject.name}: a message")

        subject.send(:logdebug , "a message")
      end
    end
  end
end
