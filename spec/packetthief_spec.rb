require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PacketThief do
  describe "setting an implementation" do
    context "when no implementation has been previously set" do
      before(:each) { PacketThief.implementation = nil }
      after(:each) { PacketThief.implementation = nil }

      it "guesses an implementation when an unknown method is called" do
        @mod = Class.new
        PacketThief.should_receive(:guess_implementation).and_return(@mod)
        @mod.should_receive(:foo)

        PacketThief.implementation.should == nil
        PacketThief.foo
        PacketThief.implementation.should == @mod
      end

    end

    context "when the implementation is set to PacketThief::Impl::Netfilter" do
      before(:each) { PacketThief.implementation = PacketThief::Impl::Netfilter }
      after(:each) { PacketThief.implementation = nil }
      it "reports that it uses the Netfilter implementation" do
        PacketThief.implementation.should == PacketThief::Impl::Netfilter
      end
      it "forwards method calls Netfilter" do
        PacketThief::Impl::Netfilter.should_receive(:foo)

        PacketThief.foo
      end
    end

    context "when the implementation is set to :netfilter" do
      before(:each) { PacketThief.implementation = :netfilter }
      after(:each) { PacketThief.implementation = nil }
      it "reports that it uses the Netfilter implementation" do
        PacketThief.implementation.should == PacketThief::Impl::Netfilter
      end
      it "forwards method calls Netfilter" do
        PacketThief::Impl::Netfilter.should_receive(:foo)

        PacketThief.foo
      end
    end
  end
end
