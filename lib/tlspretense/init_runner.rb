module TLSPretense
  class InitRunner
    include FileUtils

    def initialize(args, stdin, stdout)
      @args = args
      @stdin = stdin
      @stdout = stdout
    end

    def run
      usage if @args.length != 1
      path = @args[0]

      # Create the directory
      @stdout.puts "Creating `#{path}'"
      raise "Error: #{path} already exists!" if Dir.exist? path
      mkdir_p path, :verbose => true

      # Copy over the skeleton files
      @stdout.puts "Populating..."
      skeldir = File.join(File.dirname(__FILE__), 'skel')
      cp_r Dir.glob(File.join(skeldir,'*')), path, :verbose => true

      @stdout.puts "Now cd to #{path} and edit config.yml to suit your needs."
    end

    def usage
      @stdout.puts <<-QUOTE
Usage: #{0} init PATH

Creates a new TLSPretense working directory at PATH.
QUOTE
    end
  end
end
