

module SSLTest
  # EM handler to handle keyboard input while a test is running.
  module InputHandler

    def initialize(stdin=$stdin)
      @stdin = stdin
      @actions = {}

      # Set the term to accept keystrokes immediately.
      @stdin.enable_raw_chars
    end

    def unbind
      # Clean up by resotring the old termios
      @stdin.disable_raw_chars
    end

    # Receives one character at a time.
    def receive_data(data)
      raise "data was longer than 1 char: #{data.inspect}" if data.length != 1
      if @actions.has_key? data
        @actions[data].call
      end
    end

    def on(char, blk=nil, &block)
      puts "Warning: setting a keyboard handler for a keystroke that is longer than one char: #{char.inspect}" if char.length != 1
      raise ArgumentError, "No block passed in" if blk == nil and block == nil
      @actions[char] = ( blk ? blk : block)
    end

  end
end
