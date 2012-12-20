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
      check_environment
      init_project(path)
    end

    def check_environment
      @stdout.puts "Ruby and OpenSSL compatibility check..."
      # Ruby check:
      # TODO: detect non-MRI versions of Ruby such as jruby, ironruby
      if ruby_version[:major] < 1 or ruby_version[:minor] < 9 or ruby_version[:patch] < 3
        @stdout.puts <<-QUOTE.gsub(/^          /,'')
          Warning: You are running TLSPretense on an unsupported version of Ruby:

              RUBY_DESCRIPTION: #{RUBY_DESCRIPTION}

          Use it at your own risk! TLSPretense was developed and tested on MRI Ruby
          1.9.3. However, bug reports are welcome for Ruby 1.8.7 and later to try and
          improve compatibility.

          QUOTE
      end
      unless openssl_supports_sni?
        @stdout.puts <<-QUOTE.gsub(/^          /,'')

          Warning: Your version of Ruby and/or OpenSSL does not have the ability to set
          the SNI hostname on outgoing SSL/TLS connections.

          Testing might work fine, but if the client being tested sends the SNI TLS
          extension to request the certificate for a certain hostname, TLSPretense will
          be unable to request the correct certificate from the destination, which may
          adversely affect testing.

          QUOTE
      end
    end

    def ruby_version
      @ruby_version ||= (
        v = {}
        m = /^(.+)\.(.+)\.(.+)$/.match(RUBY_VERSION)
        v[:major] = m[1].to_i
        v[:minor] = m[2].to_i
        v[:patch] = m[3].to_i
        v
      )
    end

    def openssl_supports_sni?
      OpenSSL::SSL::SSLSocket.public_instance_methods.include? :hostname=
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

        Otherwise you can use the preinstalled CA certificate or delete the ca
        directory and run:

            tlspretense ca

        to generate a new CA (which you will then need to install so that the software
        you are testing will trust it).

        Refer to the guides on http://isecpartners.github.com/tlspretense/ for more
        information on configuring your host to run TLSPretense.
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
