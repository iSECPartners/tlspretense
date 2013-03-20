
module TLSPretense
  module ExtCompat
    # In Ruby versions before 1.9.3, OpenSSL::PKey.read does not exist. It is
    # not something that can be easily back-ported (it is written in C with
    # OpenSSL functions that are not directly exposed through the Ruby
    # library), so this module provides a partial reimplementation suitable for
    # TLSPretense's purposes.
    #
    # It blindly tries each class until one works. If none work, it finally
    # gives up. The error message won't ever be particularly helpful.
    module OpenSSLPKeyRead
      def read(data, passwd=nil)
        begin
          OpenSSL::PKey::RSA.new(data, passwd)
        rescue OpenSSL::PKey::RSAError => e
          begin
            OpenSSL::PKey::DSA.new(data, passwd)
          rescue OpenSSL::PKey::DSAError
            begin
              OpenSSL::PKey::EC.new(data, passwd)
            rescue OpenSSL::PKey::ECError
              raise "Failed to read a private key. Is the password correct?"
            end
          end
        end
      end

      def self.check_and_apply_patch
        unless ::OpenSSL::PKey.respond_to? :read
          $stderr.puts "Warning: OpenSSL::PKey does not respond to :read (added in Ruby 1.9.3). Monkeypatching it to provide enough functionality for TLSPretense."
          ::OpenSSL::PKey.extend(self)
        end
      end

    end
  end
end
