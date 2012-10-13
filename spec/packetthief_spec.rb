require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe PacketThief do
  describe "setting and implementation" do
    context "when no implementation has been previously set" do
      before(:each) do
        PacketThief.should_not_receive(:implementation=)
        PacketThief.stub(:implementation).and_return(nil)
      end
      it "guesses an implementation when a method is called" do
        PacketThief.should_receive(:guess_implementation).and_return(double('fooimpl', :foo => nil))

        PacketThief.foo
      end
    end

    context "when the implementation is set to :netfilter" do
      before(:each) { PacketThief.implementation = :netfilter }
      it "uses Netfilter" do
        PacketThief::Impl::Netfilter.should_receive(:foo)

        PacketThief.foo
      end
    end
  end
end
