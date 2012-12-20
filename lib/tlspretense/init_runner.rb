module TLSPretense
  class InitRunner
    include FileUtils

    class InitError < CleanExitError ; end

    def initialize(args, stdin, stdout)
      @args = args
      @stdin = stdin
      @stdout = stdout
    end

    def run
      if @args.length != 1
        usage
        return
      end
      path = @args[0]
      init_project(path)
    end



    def init_project(path)
      @stdout.print "Creating #{path}... "
      raise InitError, "#{path} already exists!" if File.exist? path
      mkdir_p path
      @stdout.puts "Done"

      @stdout.puts "Populating #{path}... "
      skeldir = File.join(File.dirname(__FILE__), 'skel')
      @stdout.print '    ' ; cp_r Dir.glob(File.join(skeldir,'*')), path, :verbose => true
      @stdout.puts "Done"

      @stdout.puts <<-QUOTE.gsub(/^        /,'')
        Finished!

        Now cd to #{path} and edit config.yml to suit your needs.

        If you have an existing CA certificate and key you would like to use, you
        should copy the PEM encoded certificate to:

            #{path}/ca/goodcacert.pem

        And you should copy the PEM encoded private key to:

            #{path}/ca/goodcakey.pem
        QUOTE
    end

    def usage
      @stdout.puts <<-QUOTE.gsub(/^        /,'')
        Usage: #{0} init PATH

        Creates a new TLSPretense working directory at PATH.
        QUOTE
    end
  end
end
